@if(0)==(0) echo off
@REM ===============================================================
@REM    Copyright (C) 2014-2016 BizStation Corp All rights reserved.
@REM 
@REM    This program is free software; you can redistribute it and/or
@REM    modify it under the terms of the GNU General Public License
@REM    as published by the Free Software Foundation; either version 2
@REM    of the License, or (at your option) any later version.
@REM 
@REM    This program is distributed in the hope that it will be useful,
@REM    but WITHOUT ANY WARRANTY; without even the implied warranty of
@REM    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
@REM    GNU General Public License for more details.
@REM 
@REM    You should have received a copy of the GNU General Public License
@REM    along with this program; if not, write to the Free Software 
@REM    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  
@REM    02111-1307, USA.
@REM ===============================================================
::  SysNative alias is avalable if this is 32bit-cmd.exe on 64bit-system.
::  %WinDir%\SysNative\cmd.exe is 64bit-cmd.exe.
if exist %WinDir%\SysNative\cmd.exe (
  ::echo 32bit-cmd.exe on 64bit-Windows - call 64bit-cmd.exe
  "%WinDir%\SysNative\cmd.exe" /C "%~f0" %*
  exit /b %ERRORLEVEL%
) else (
  ::echo 32bit-cmd.exe on 32bit-Windows or 64bit-cmd.exe on 64bit-Windows
  cscript //nologo //E:JScript "%~f0" %*
  exit /b %ERRORLEVEL%
)
@end

var fso = new ActiveXObject('Scripting.FileSystemObject');
var ado = new ActiveXObject('ADODB.Stream');
var shell = new ActiveXObject('WScript.Shell');
var shapp = new ActiveXObject('Shell.Application');
var URL_BASE = 'https://www.bizstation.jp/al/transactd/download/';

function uniquePush(arr, item) {
  var s_item = ('' + item).toLowerCase();
  for (var i = 0; i < arr.length; i++) {
    if (('' + arr[i]).toLowerCase() == s_item)
      return false;
  }
  arr.push(item);
  return true;
}

function padding(val, max) {
  max = '' + max;
  var s = '' + val;
  while (max.length > s.length)
    s = ' ' + s;
  return s;
}

function makeSelectListString(arr, needOther) {
  if (typeof needOther == 'undefined')
    needOther = true;
  var ret = [];
  var max = arr.length + 1;
  for (var i = 0; i < arr.length; i++)
    ret.push('  ' + padding(i + 1, max) + '. ' + arr[i]);
  if (ret.length == 0)
    return '';
  if (needOther)
    ret.push('  ' + max + '. Other');
  return ret.join('\n');
}

function timeoutLoop(timeout_msec, breakCheckerFunction, timeoutFunction) {
  if (typeof breakCheckerFunction != 'function')
    breakCheckerFunction = function(){ return true; };
  if (typeof timeoutFunction != 'function')
    timeoutFunction = function(){ return false };
  var use_timeout = (timeout_msec > 0);
  while (true) {
    if (breakCheckerFunction())
      return true;
    WScript.Sleep(50);
    if (use_timeout) {
      timeout_msec = timeout_msec - 50;
      if (timeout_msec < 0) {
        return timeoutFunction();
      }
    }
  }
}

function execWait(cmd, timeout_msec, terminateIfTimeout) {
  if (typeof terminateIfTimeout == 'undefined')
    terminateIfTimeout = false;
  if (typeof timeout_msec == 'undefined')
    timeout_msec = 0;
  var e = shell.Exec(cmd);
  var succeed = timeoutLoop(timeout_msec,
    function(){ return (e.Status != 0) },
    function(){
      if (terminateIfTimeout)
        e.Terminate();
      return false;
    }
  );
  var timeouted = !succeed;
  var stdout = '';
  if (!e.StdOut.AtEndOfStream)
    stdout = e.StdOut.ReadAll();
  var stderr = '';
  if (!e.StdErr.AtEndOfStream)
    stderr = e.StdErr.ReadAll();
  if (e.Status == 0) {
    return { finished:false, exitCode:-1, timeout:timeouted, stdout:stdout, stderr:stderr };
  }
  return { finished:true, exitCode:e.ExitCode, timeout:timeouted, stdout:stdout, stderr:stderr };
}

function inputLoop(preinput, validate) {
  while (true) {
    var pre_data = preinput();
    var ret = WScript.StdIn.ReadLine();
    var valid = validate(ret, pre_data);
    if (valid[0])
      return valid[1];
  }
}

function validate_word(ret, pre_data) {
  ret = ret.replace(/[\n\r]/g, '').replace(/^\s*(.*)\s*$/, '$1');
  if (ret.length == 0)
    return [false, ''];
  return [true, ret];
}

function validate_word_empty(ret, pre_data) {
  return [true, ret.replace(/[\n\r]/g, '').replace(/^\s*(.*)\s*$/, '$1')];
}

var CONFIRM_YES     = 1;
var CONFIRM_NO      = 0;

function confirmYN(pre, validate) {
  if (typeof pre != 'function')
    pre = function(){ WScript.StdOut.Write('Sure? [Y/N(yes/no)]:'); };
  if (typeof validate != 'function') {
    validate = function(ret, pre_data) {
      ret = ret.replace(/[\n\r\s]/g, '').toLowerCase();
      switch (ret) {
        case 'y':
        case 'yes':
          return [true, CONFIRM_YES];
        case 'n':
        case 'no':
          return [true, CONFIRM_NO];
      }
      return [false, null];
    };
  }
  return inputLoop(pre, validate);
}

function getTempFilePath() {
  return fso.BuildPath(fso.GetSpecialFolder(2/*temp folder*/), fso.GetTempName());
}

function getXHR() {
  try {
    return new ActiveXObject('Msxml6.XMLHTTP');
  } catch(e) {}
  try {
    return new ActiveXObject('Msxml5.XMLHTTP');
  } catch(e) {}
  try {
    return new ActiveXObject('Msxml4.XMLHTTP');
  } catch(e) {}
  try {
    return new ActiveXObject('Msxml3.XMLHTTP');
  } catch(e) {}
  return new ActiveXObject('Msxml2.XMLHTTP');
}
var xhr = getXHR();

function urlGET(url, timeout_msec) {
  xhr.open('GET', url);
  xhr.send();
  return timeoutLoop(timeout_msec,
    function(){ return (xhr.readyState == 4); },
    function(){ xhr.abort(); return false; }
  );
}

function createFolder(dir) {
  if (fso.FolderExists(dir))
    return true;
  var stack = [];
  var c_dir = dir;
  while (true) {
    var p_dir = fso.GetParentFolderName(c_dir);
    if (fso.FolderExists(p_dir)) {
      try {
        fso.CreateFolder(c_dir);
        while (stack.length > 0) {
          c_dir = fso.BuildPath(c_dir, stack.pop());
          fso.CreateFolder(c_dir);
        }
      } catch(e) {
        return false;
      }
      return true;
    } else {
      var name = fso.GetFileName(c_dir);
      if (name.length <= 0)
        return false;
      stack.push(name);
      c_dir = p_dir;
    }
  }
  return true;
}

function unzip(zip_path, to_dir, option) {
  if (typeof option == 'undefined')
    option = 0;
  if (! fso.FileExists(zip_path))
    return false;
  if (! fso.FolderExists(to_dir)) {
    var ret = createFolder(to_dir);
    if (! ret)
      return false;
  }
  try {
    shapp.NameSpace(to_dir).CopyHere(shapp.NameSpace(zip_path).Items(), option);
  } catch(e) {
    return false;
  }
  return true;
}

function toCRLF(s) {
  return s.replace(/\r\n?/g, '\n').replace(/\n/g, '\r\n');
}

function read(ado, file, sjis) {
  if(typeof sjis === 'undefined')
    sjis = false;
  try {
    ado.Type = 2; // adTypeText
    ado.charset = 'utf-8';
    if (sjis)
      ado.charset = 'Shift_JIS';
    ado.Open();
    ado.LoadFromFile(file);
    var s = ado.ReadText(-1); // adReadAll
    ado.Close();
    return s;
  } catch (e) {
    ado.Close();
    WScript.StdErr.WriteLine('can not read ' + file + '.');
    throw e;
  }
  return '';
}

function write(ado, file, source, sjis) {
  if(typeof sjis === 'undefined')
    sjis = false;
  try {
    ado.Type = 2; // adTypeText
    ado.charset = 'utf-8';
    if (sjis)
      ado.charset = 'Shift_JIS';
    ado.Open();
    ado.WriteText(source, 0); // adWriteChar
    if (!sjis) {
      ado.Position = 0;
      ado.Type = 1; // adTypeBinary
      ado.Position = 3;  // skip 3 bytes BOM
      var bin = ado.Read();
      ado.Close()
      ado.Open()
      ado.Write(bin);
    }
    ado.SaveToFile(file, 2); // adSaveCreateOverwrite
    return true;
  } catch (e) {
    ado.Close();
    WScript.StdErr.WriteLine('can not write ' + file + '.');
    throw e;
  }
  return false;
}

function runMySQLBinary(binpath, opt, mysqluser, password, timeout) {
  if (typeof mysqluser == 'undefined' || mysqluser == null)
    mysqluser = '';
  if (typeof timeout != 'number' || timeout == NaN)
    timeout = 30 * 1000; // 30 sec
  var cmd = '"' + binpath + '" ';
  if (mysqluser.length > 0) {
    cmd = cmd + '-u"' + mysqluser + '" ';
    if (typeof password == 'string')
      cmd = cmd + '--password="' + password + '" ';
    else
      cmd = cmd + '-p ';
  }
  cmd = cmd + opt;
  //WScript.echo(cmd);
  var ret = execWait(cmd, timeout, false);
  if (ret.timeout)
    return [false, '', 'command timeout'];
  return [(ret.exitCode == 0), ret.stdout, ret.stderr];
}

function fixMySQLErrorMessage(s) {
  return s.replace('Warning: Using a password on the command line interface can be insecure.', '')
    .replace(/^[\r\n]*(.*?)[\r\n]*$/, '$1');
}

function showHTADialog(source) {
  var cmd = "javascript:new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(0).ReadAll()";
  var oExec = shell.Exec('mshta.exe "' + cmd + '"');
  oExec.StdIn.WriteLine(source);
  oExec.StdIn.Close();
  return oExec.StdOut.ReadAll().replace(/^[\r\n \t]*(.*?)[\r\n \t]*$/, '$1');
}

var PASSBOX_SOURCE = '<!DOCTYPE html><html lang="ja">' +
'<head><meta charset="UTF-8"><meta http-equiv="Content-Type" content="text/html; charset=utf-8">' +
'<style type="text/css">*{font-size:16px;}button{padding:1px 0.5em;margin:0 1em;}</style>' +
'<title>Input password</title><script type="text/javascript">var w = 320;var h = 100;' +
'window.resizeTo(w, h);window.moveTo(parseInt((screen.width - w) / 2), parseInt((screen.height - h) / 2));' +
'function send(){var val=document.getElementById("input_password").value;' +
'var out=new ActiveXObject("Scripting.FileSystemObject").GetStandardStream(1);' +
'if(typeof out == "object")out.Write(val);window.close();}</script>' +
'<hta:application showintaskbar="yes" border="dialog" borderstyle="raised" contextmenu="yes" innerborder="no" ' +
'maximizebutton="no" minimizebutton="no" scroll="no" scrollflat="no" navigable="no" /></head>' +
'<body><input type="password" id="input_password" />' +
'<button type="button" onclick="send();">OK</button></body></html>';

//
//  [1] Search database and get information
//

var df_regexps = [/ "--(defaults-file)=([^"]+)"/,
                  / --(defaults-file)="([^"]+)"/,
                  / --(defaults-file)=([^" ]+)/,
                  / "--(defaults-extra-file)=([^"]+)"/,
                  / --(defaults-extra-file)="([^"]+)"/,
                  / --(defaults-extra-file)=([^" ]+)/];
function readServicePathName(PathName) {
  var ret = { path:'', dir:'', opt:'', cnf:'' };
  var s = PathName.replace(/^\s*(.*?)\s*$/g, '$1');
  // get exe path
  var search_char = ' ';
  if (s.substring(0, 1) == '"') {
    search_char = '"';
    s = s.substring(1, s.length);
  }
  var i = s.indexOf(search_char);
  if (i < 0) {
    ret.path = s;
    return ret;
  }
  ret.path = s.substring(0, i);
  ret.dir = ret.path.replace(/\\bin\\mysqld.exe$/i, '');
  // defaults-file (Use only the given option file)
  // defaults-extra-file (Read this option file after the global option file)
  for (var i = 0; i < df_regexps.length; i++) {
    var m = s.match(df_regexps[i]);
    if (m != null) {
      ret.opt = m[1];
      ret.cnf = m[2];
      return ret;
    }
  }
  return ret;
}

var mysqld_path_regex = /^"?(.*mysqld\.exe).*/i;
function getRunningMySQL() {
  var wmi = GetObject('winmgmts:\\\\.\\root\\cimv2');
  var items = wmi.ExecQuery('select * from Win32_Process');
  var e = new Enumerator(items);
  var ret = [];
  var pathes = [];
  var props = ['CommandLine', 'ExecutablePath', 'Name', 'Status'];
  for (; !e.atEnd(); e.moveNext()) {
    var item = e.item();
    if (mysqld_path_regex.test(item.Name)) {
      var rng = readServicePathName(item.CommandLine);
      if (fso.FileExists(rng.path)) {
        if (uniquePush(pathes, rng.path))
          ret.push(rng);
      }
    }
  }
  return ret;
}

function detectDB() {
  var pre_confirm = function(){
    WScript.Echo('Retry to search mysqld.exe process?');
    WScript.StdOut.Write('[Y/N(yes to retry/no to cancel installation)]:');
  };
  while (true) {
    WScript.StdOut.Write('search mysqld.exe process ... ');
    var rng = getRunningMySQL();
    if (rng.length > 0)
      return rng[0];
    WScript.Echo('\n\nPlease start MySQL/MariaDB server.\n');
    var confirm = confirmYN(pre_confirm);
    if (confirm == CONFIRM_NO)
      return false;
    WScript.Echo('');
  }
}

var ini_regex = /^(.*?my\.ini) /i;
var cnf_regex = /^(.*?my\.cnf) /i;
function readVerboseString(s) {
  var ret = {};
  // plugin_dir
  ret['plugin_dir'] = '';
  var m = s.match(/^plugin-dir +(.+)$/im);
  if (m != null)
    ret['plugin_dir'] = m[1].replace(/[\r\n]/g, '');
  if (ret.plugin_dir.length > 0)
    ret.plugin_dir = fso.GetAbsolutePathName(ret.plugin_dir);
  // split with line
  var s_arr = s.replace(/[\n\r]+/g, "\r").split(/\r/);
  // my.ini or my.cnf
  ret['cnffiles'] = [];
  var m = s.match(/^(.*my\.ini .+)$/im);
  if (m != null) {
    var cnfs = [];
    var s = m[1].replace(/[\n\r]/g, '');
    while (s.length > 0) {
      var m_ini = s.match(ini_regex);
      var m_cnf = s.match(cnf_regex);
      if (m_ini == null && m_cnf == null)
        break;
      var s_ini = (m_ini != null) ? m_ini[1] : '';
      var s_cnf = (m_cnf != null) ? m_cnf[1] : '';
      var max_length = s_ini.length;
      if (s_ini.length > s_cnf.length) {
        s_ini = s_ini.substring(s_cnf.length, s_ini.length).replace(/^\s*(.+)\s*$/, '$1');
        s_cnf = s_cnf.replace(/^\s*(.+)\s*$/, '$1');
        if (s_cnf.length > 0)
          cnfs.push(s_cnf);
        if (s_ini.length > 0)
          cnfs.push(s_ini);
      } else {
        max_length = s_cnf.length;
        s_cnf = s_cnf.substring(s_ini.length, s_cnf.length).replace(/^\s*(.+)\s*$/, '$1');
        s_ini = s_ini.replace(/^\s*(.+)\s*$/, '$1');
        if (s_ini.length > 0)
          cnfs.push(s_ini);
        if (s_cnf.length > 0)
          cnfs.push(s_cnf);
      }
      s = s.substring(max_length, s.length);
    }
    ret['cnffiles'] = cnfs;
  }
  // version
  var ver_s = s_arr[s_arr.length - 1];
  ret['version'] = '';
  m = ver_s.match(/ver ([0-9]+\.[0-9]+\.[0-9]+)[^ ]* /i);
  if (m != null)
    ret['version'] = m[1];
  // product
  if ((/MariaDB/i).test(ver_s))
    ret['product'] = 'mariadb';
  else
    ret['product'] = 'mysql';
  // 32/64bit
  if ((/ Win64 /i).test(ver_s))
    ret['bit'] = 'win64';
  else
    ret['bit'] = 'win32';
  return ret;
}

function getInfo(bin) {
  var temp_cmd = getTempFilePath() + '.cmd';
  var temp_ret = getTempFilePath() + '.txt';
  var timeout = 30 * 1000 // 30 sec
  // create get_info command file
  var f = null;
  try {
    f = fso.OpenTextFile(temp_cmd, 2/*ForWriting*/, true/*create*/, false/*ASCII*/);
    f.Write('"' + bin.path + '" --verbose --help > "' + temp_ret + '"\n');
    f.Write('"' + bin.path + '" --version >> "' + temp_ret + '"\n');
    f.Close();
    f = null;
  } catch (e) {
    if (f != null)
      f.Close();
    WScript.Echo('\nFailed to get MySQL info. (1)');
    return false;
  }
  var succeed = timeoutLoop(timeout, function(){ return fso.FileExists(temp_cmd) });
  if (!succeed) {
    WScript.Echo('\nFailed to get MySQL info. (2)');
    return false;
  }
  // run get_info command file - result file will be generated
  var ret = execWait(temp_cmd, timeout);
  succeed = (ret.exitCode == 0);
  if (succeed)
    succeed = timeoutLoop(timeout, function(){ return fso.FileExists(temp_ret) });
  if (!succeed) {
    WScript.Echo('\nFailed to get MySQL info. (3)');
    return false;
  }
  fso.DeleteFile(temp_cmd);
  // read result file
  var s = '';
  try {
    f = fso.OpenTextFile(temp_ret, 1/*ForReading*/, false/*create*/, false/*ASCII*/);
    s = f.ReadAll();
    f.Close();
  } catch (e) {
    if (f != null)
      f.Close();
    succeed = false;
  }
  fso.DeleteFile(temp_ret);
  if (s.length == 0 || !succeed) {
    WScript.Echo('\nFailed to get MySQL info. (4)');
    return false;
  }
  var ver = readVerboseString(s);
  for (i in bin)
    ver[i] = bin[i];
  return ver;
}

function getLatestVersion() {
  WScript.StdOut.Write('get Transactd version from bizstation.jp ... ');
  var url = URL_BASE + 'VERSIONS.txt';
  var finished = urlGET(url, 30 * 1000); // 30 sec
  if (! finished) {
    WScript.Echo('\nCould not get version from bizstation.jp');
    return '';
  }
  var s = xhr.responseText;
  var td_vers = s.replace(/[\r\n]+/g, "\r").split(/\r/);
  if (td_vers.length <= 0 || td_vers[0].length <= 0) {
    WScript.Echo('\nCould not get version from bizstation.jp');
    return '';
  }
  WScript.Echo('done. [' + td_vers[0] + ']');
  return td_vers[0];
}

//
//  [2] Input username and password
//

var GRANT_REGEX = /GRANT [A-Z ]+ ON .+ TO '(.*)'@'.*'/gi;
function connectTestMySQL(bin, user, password) {
  var ret = runMySQLBinary(fso.BuildPath(bin.dir, 'bin\\mysql.exe'),
    '-e "show grants;"', user, password);
  if (! ret[0])
    return false;
  var validuser = false;
  GRANT_REGEX.lastIndex = 0;
  while (true) {
    var m = GRANT_REGEX.exec(ret[1]);
    if (m == null)
      break;
    if (m[1].toLowerCase() == user.toLowerCase())
      validuser = true;
  }
  return validuser;
}

function inputUserPassword(bin) {
  var pre_name = function() {
    WScript.Echo('Input username who can GRANT/INSTALL PLUGIN');
    WScript.StdOut.Write("(Input 'root' if you don't know.):");
  };
  while (true) {
    var rootuser = inputLoop(pre_name, validate_word);
    WScript.Echo('\nInput password for ' + rootuser);
    var password = showHTADialog(PASSBOX_SOURCE);
    WScript.StdOut.Write('connect to database... ')
    if (connectTestMySQL(bin, rootuser, password)) {
      WScript.Echo('done.');
      return [rootuser, password];
    }
    WScript.Echo('\n\nUser [' + rootuser + '] can not connect to database.');
  }
}

//
//  [3] Check configurations
//

var SERCH_PLUGIN_SQL = "SELECT PLUGIN_NAME FROM INFORMATION_SCHEMA.PLUGINS WHERE PLUGIN_NAME = 'transactd';";
function checkInstallation(bin, rootuser, password) {
  var ret = runMySQLBinary(fso.BuildPath(bin.dir, 'bin\\mysql.exe'),
    '-e "' + SERCH_PLUGIN_SQL + '"', rootuser, password);
  if (! ret[0]) {
    WScript.Echo('\nFailed to Installation check. (' + fixMySQLErrorMessage(ret[2]) + ')');
    return [false, null];
  }
  return [true, (ret[1].replace(/[ \s\t\n\r]/g, '').length > 0)];
}

function checkPluginInstallation(bin, rootuser, password) {
  WScript.StdOut.Write('search transactd.dll... ');
  var plugin_path = fso.BuildPath(bin.plugin_dir, 'transactd.dll');
  var ret = { dir:bin.plugin_dir, installed:false, failed:false,
    exists:fso.FileExists(plugin_path) };
  WScript.Echo('done. [file ' + (ret.exists ? '' : 'not ') + 'exists]');
  WScript.StdOut.Write('installation checking... ');
  var chk = checkInstallation(bin, rootuser, password);
  ret.failed = (! chk[0]); // Installation check failed
  ret.installed = chk[1];
  if (! ret.failed)
    WScript.Echo('done. [' + (ret.installed ? '' : 'not ') + 'installed]');
  return ret;
}

function searchConfigFile(bin) {
  var ret = { file:'', exists:false };
  if (typeof bin.cnf == 'string' && bin.cnf.length > 0)
    ret.file = bin.cnf;
  else if (typeof bin.cnffiles != 'undefined' && bin.cnffiles.length > 0) {
    var def = '';
    for (var i = bin.cnffiles.length - 1; i >= 0; i--) {
      if (fso.FileExists(bin.cnffiles[i])) {
        ret.file = bin.cnffiles[i];
        break;
      }
      var extName = fso.GetExtensionName(bin.cnffiles[i]).toLowerCase();
      if (def.length == 0 && ((extName== 'ini' || extName== 'cnf')))
        def = bin.cnffiles[i];
    }
    if (ret.file.length == 0)
      ret.file = def;
  }
  if (ret.file.length == 0)
    return ret;
  ret.exists = fso.FileExists(ret.file);
  return ret;
}

var hostcheck_username_regex =
  /^[ \t]*(?:loose\-)?transactd_hostcheck_username[ \t]*=[ \t]*([^\n\r]*?)[ \t]*$/mi;
var sectionRegex = /^[ \t]*\[([^\[\]\n\r]+)\][ \t]*$/mgi;
function searchHostcheckUsername(source) {
  var ret = { start:-1, end:-1, value:'', sectionend:-1 };
  hostcheck_username_regex.lastIndex = 0;
  var m = source.match(hostcheck_username_regex);
  if (m != null) {
    ret.start = m.index;
    ret.end = hostcheck_username_regex.lastIndex;
    if (m[1].substring(0, 1) == '"' && m[1].substring(m[1].length - 1, m[1].length) == '"')
      m[1] = m[1].substring(1, m[1].length - 1);
    ret.value = m[1];
    return ret;
  }
  sectionRegex.lastIndex = 0;
  var found_mysqld_section = false;
  while (true) {
    var ms = sectionRegex.exec(source);
    if (ms == null)
      break;
    if (ms[1].toLowerCase() == 'mysqld') {
      found_mysqld_section = true;
    } else if (found_mysqld_section) {
      ret.sectionend = ms.index;
      break;
    }
  }
  if (found_mysqld_section && ret.sectionend < 0)
    ret.sectionend = source.length;
  return ret;
}

function checkConfigFile(bin) {
  WScript.StdOut.Write('search config file... ');
  var cnf = searchConfigFile(bin);
  var ret = { file:cnf.file, exists:cnf.exists,
    start:-1, end:-1, sectionend:-1, value:'', source:'' };
  if (ret.file.length <= 0) {
    WScript.Echo('\nCould not found config file.');
    return ret;
  }
  WScript.Echo('done.');
  if (! ret.exists)
    return ret;
  WScript.StdOut.Write('load config file... ');
  ret.source = read(ado, ret.file);
  var hcun = searchHostcheckUsername(ret.source);
  ret.start = hcun.start;
  ret.end = hcun.end;
  ret.sectionend = hcun.sectionend;
  ret.value = hcun.value;
  var configExists = cnf.start >= 0 && cnf.value.length > 0;
  WScript.Echo('done. [configuration' + (configExists ? '' : ' not') + ' exists]');
  return ret;
}

function getIPAddresses() {
  var ret = [];
  var wmi = GetObject('winmgmts:\\\\.\\root\\cimv2');
  var items = wmi.ExecQuery('select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE');
  var e = new Enumerator(items);
  for (; !e.atEnd(); e.moveNext()) {
    var item = e.item();
    if (item.IPAddress(0) != null)
      ret.push(item.IPAddress(0));
  }
  return ret;
}

function makeAccessibleHostList() {
  var titles = ['localhost only'];
  var values = ['localhost'];
  var ips = getIPAddresses();
  for (var i = 0; i < ips.length; i++) {
    var ip = ips[i].split('.');
    if (ip.length != 4)
      continue;
    var ip_part = ip.slice(0, 3).join('.') + '.';
    titles.push(ip_part + 'x');
    values.push(ip_part + '0/255.255.255.0');
  }
  return [titles, values];
}

function pre_inputAccessibleHost() {
  WScript.Echo('Set accessible hosts with address mask (multiple-input with comma).');
  WScript.Echo('  (ex) "192.168.1.0/255.255.255.0"');
  WScript.Echo('  (ex) "192.168.1.0/255.255.255.0, 192.168.2.0/255.255.255.0"');
  WScript.Echo('Input hosts [or empty to return to option list]:');
}

function validate_inputAccessibleHost(ret, pre_data) {
  ret = ret.replace(/[\n\r\s \t]/g, '');
  var values = [];
  var splited = ret.split(',');
  for (var i = 0; i < splited.length; i++) {
    if (splited[i].length > 0)
      uniquePush(values, splited[i]);
  }
  return [true, values];
}

var INT_COMMA_REGEX = /^[0-9\,]+$/;
function selectAccessibleHost(accessClass) {
  var lists = makeAccessibleHostList();
  var list_str = makeSelectListString(lists[0], true);
  var max_id = lists[0].length + 1;
  var pre = function(){
    WScript.StdOut.Write('Choose [1-' + max_id +
      ' or multiple-choice with comma like "1,2"]:');
  };
  var validate = function(ret, pre_data) {
    ret = ret.replace(/[\n\r\s]/g, '');
    if (INT_COMMA_REGEX.test(ret)) {
      var values = [];
      var splited = ret.split(',');
      for (var i = 0; i < splited.length; i++) {
        if (splited[i].length <= 0)
          continue;
        var num = parseInt(splited[i], 10);
        if (num >= 1 && num <= max_id)
          uniquePush(values, num);
      }
      if (values.length > 0)
        return [true, values];
    }
    if (ret.length > 0)
      WScript.Echo('*** "' + ret + '" is not valid. ***');
    return [false, []];
  };
  while (true) {
    var hosts = [];
    var needInput = false;
    var ret = [];
    ret[0] = accessClass;
    if (userInterface && accessClass < max_id)
    {
      WScript.Echo('Select accessible hosts option.');
      WScript.Echo(list_str);
      ret = inputLoop(pre, validate);
    }
    for (var i = 0; i < ret.length; i++) {
      if (ret[i] < max_id)
        hosts.push(lists[1][ret[i] - 1]);
      else
        needInput = true;
    }
    if (! needInput)
      return hosts;
    WScript.Echo('');
    var hostmasks = inputLoop(pre_inputAccessibleHost, validate_inputAccessibleHost);
    if (hostmasks.length > 0)
      return hosts.concat(hostmasks);
    WScript.Echo('');
  }
}

function inputConfigurations(cnf, user, accessClass) {
  var pre_uname = function() {
    WScript.Echo('Create user for Transactd on MySQL/MariaDB.');
    WScript.Echo('  (Use "transactd" if you are wondering.)');
    WScript.StdOut.Write('Input user name [empty to use "transactd"]:');
  };
  WScript.Echo('');
  var uname = user;
  if (uname == "")
    uname = inputLoop(pre_uname, validate_word_empty);
  if (uname.length == 0)
    uname = 'transactd';
  WScript.Echo('');
  var hostmasks = selectAccessibleHost(accessClass);
  return [uname, hostmasks];
}

//
//  [4] Confirm Installation
//

function confirmInstallation(td_ver, bin, plg, needConfigure, unamehosts, cnf) {
  WScript.Echo('');
  WScript.Echo('Database      : ' + bin.product + ' ' + bin.version + ' ' + bin.bit);
  WScript.Echo('Plugin_dir    : ' + plg.dir);
  WScript.Echo('Transactd ver : ' + td_ver);
  if (needConfigure) {
    WScript.Echo('');
    WScript.Echo('Config file        : ' + cnf.file);
    WScript.Echo('hostcheck_username : ' + unamehosts[0]);
    WScript.Echo('Accessible hosts   : ' + unamehosts[1][0]);
    for (var i = 1; i < unamehosts[1].length; i++)
      WScript.Echo('                     ' + unamehosts[1][i]);
  }
  WScript.Echo('');
  if (userInterface)
    return (confirmYN() == CONFIRM_YES);
  return CONFIRM_YES;
}

//
//  [5] Install
//

function uninstallPlugin(bin, rootuser, password) {
  var ret = runMySQLBinary(fso.BuildPath(bin.dir, 'bin\\mysql.exe'),
    '-e "UNINSTALL PLUGIN transactd;"', rootuser, password);
  if ((! ret[0]) && (ret[2].indexOf('PLUGIN transactd does not exist') < 0)) {
    WScript.Echo('\nFailed to uninstall old plugin. (' + fixMySQLErrorMessage(ret[2]) + ')');
    return false;
  }
  return true;
}

function deletePluginRow(bin, rootuser, password) {
  var ret = runMySQLBinary(fso.BuildPath(bin.dir, 'bin\\mysql.exe'),
    '-e "DELETE FROM mysql.plugin WHERE name = \'transactd\';"', rootuser, password);
  if (! ret[0]) {
    WScript.Echo('\nFailed to delete plugin row. (' + fixMySQLErrorMessage(ret[2]) + ')');
    return false;
  }
  return true;
}

function makeURL(bin, td_ver) {
  //  transactd-2.0.0/transactd-win64-2.0.0_mysql-5.6.21.zip
  //  transactd-2.0.0/transactd-win64-2.0.0_mariadb-10.0.14.zip
  return URL_BASE + 'transactd-' + td_ver + '/transactd-' + bin.bit +
    '-' + td_ver + '_' + bin.product + '-' + bin.version + '.zip';
}

function downloadZip(url) {
  var timeout = 3 * 60 * 1000; // 3 min
  var finished = urlGET(url, timeout);
  if (! finished) {
    WScript.Echo('\nCould not download zip. unknown error.');
    return '';
  }
  if (xhr.status == 404) {
    WScript.Echo('\nCould not download zip.');
    WScript.Echo('  There is no zip package for this version of MySQL/MariaDB.');
    WScript.Echo('  url not found: ' + url);
    return '';
  }
  if (xhr.status != 200) {
    WScript.Echo('\nCould not download zip. [status code ' + xhr.status + ']');
    WScript.Echo('  url: ' + url);
    return '';
  }
  var tmp_zip = getTempFilePath() + '.zip';
  ado.Type = 1; // adTypeBinary
  try {
    ado.Open();
    ado.Write(xhr.responseBody);
    ado.Savetofile(tmp_zip, 2/*adSaveCreateOverWrite*/);
    ado.Close();
  } catch(e) {
    ado.Close();
    WScript.Echo('\nCould not download zip. can not write temp file.');
    WScript.Echo('  ' + e.message);
    return '';
  }
  return tmp_zip;
}

function extractPluginZip(zip_path) {
  var tmp_dir = getTempFilePath();
  var succeed = unzip(zip_path, tmp_dir);
  if (fso.FileExists(zip_path))
    fso.DeleteFile(zip_path);
  if (! succeed) {
    WScript.Echo('\nError: could not extract zip.');
    if (fso.FolderExists(tmp_dir))
      fso.DeleteFolder(tmp_dir);
    return '';
  }
  return tmp_dir;
}

function copyPluginFiles(tmp_dir, plugin_dir, td_ver) {
  var dirname = 'transactd-' + td_ver;
  var dirpath = fso.BuildPath(plugin_dir, dirname);
  try {
    // delete file
    if (fso.FileExists(dirpath)) {
      fso.DeleteFile(dirpath);
      var timeout = 5 * 1000; // 5 sec
      var succeed = timeoutLoop(timeout, function(){ return !fso.FileExists(dirpath); });
      if (! succeed)
        throw new Error('\nCould not delete file [' + dirpath + ']');
    }
    // create folder
    if (! fso.FolderExists(dirpath)) {
      var succeed = createFolder(dirpath);
      if (! succeed)
        throw new Error('\nCould not create [' + dirpath + ']');
    }
    // copy files
    var src = fso.GetFolder(tmp_dir);
    var e = new Enumerator(src.Files);
    for (; !e.atEnd(); e.moveNext()) {
      var f = e.item();
      var target = fso.BuildPath(dirpath, f.Name);
      fso.CopyFile(f.Path, target, true);
      WScript.Echo(' ' + target);
    }
    var target = fso.BuildPath(fso.GetParentFolderName(dirpath), 'transactd.dll');
    fso.CopyFile(fso.BuildPath(dirpath, 'transactd.dll'), target, true);
    WScript.Echo(' ' + target);
    fso.DeleteFolder(tmp_dir);
  } catch (e) {
    if (fso.FolderExists(tmp_dir))
      fso.DeleteFolder(tmp_dir);
    WScript.Echo('\n' + e.message);
    return false;
  }
  return true;
}

function makeGrantSQL2(uname, hostmask) {
  return "create user '" + uname + "'@'" + hostmask + "';" + 
   "GRANT USAGE ON *.* TO '" + uname + "'@'" + hostmask + "';";
}

function setAccessibleHosts2(bin, rootuser, password, uname, hosts) {
  var sqls = [];
  for (var i = 0; i < hosts.length; i++)
    sqls.push(makeGrantSQL2(uname, hosts[i]));
  if (uname == "transactd") sqls.push(makeGrantSQL2(uname, "localhost"));
  var ret = runMySQLBinary(fso.BuildPath(bin.dir, 'bin\\mysql.exe'),
    '-e "' + sqls.join('') + '"', rootuser, password);
  if (! ret[0]) {
    
    WScript.Echo('\nRun command FAILED.');
    WScript.Echo(fixMySQLErrorMessage(ret[2]));
  }
  return ret[0];
}

function makeGrantSQL(uname, hostmask) {
  return "GRANT USAGE ON *.* TO '" + uname + "'@'" + hostmask + "';";
}

function setAccessibleHosts(bin, rootuser, password, uname, hosts) {
  var sqls = [];
  for (var i = 0; i < hosts.length; i++)
    sqls.push(makeGrantSQL(uname, hosts[i]));
  if (uname == "transactd") sqls.push(makeGrantSQL(uname, "localhost"));
    
  var ret = runMySQLBinary(fso.BuildPath(bin.dir, 'bin\\mysql.exe'),
    '-e "' + sqls.join('') + '"', rootuser, password);
  if (! ret[0]) {
    return setAccessibleHosts2(bin, rootuser, password, uname, hosts);
  }
  return ret[0];
}

function makeConfigLine(uname) {
  return 'loose-transactd_hostcheck_username="' + uname + '"';
}

function createConfigFile(cnf, uname) {
  var s = '[mysqld]\n' + makeConfigLine(uname) + '\n';
  return write(ado, cnf.file, toCRLF(s), false);
}

function replaceConfig(cnf, uname) {
  var s = cnf.source.substring(0, cnf.start) +
    makeConfigLine(uname) +
    cnf.source.substring(cnf.end, cnf.source.length);
  return write(ado, cnf.file, toCRLF(s), false);
}

function addConfig(cnf, uname) {
  var s = '';
  if (cnf.sectionend < 0) { // no [mysqld] section found
    if (cnf.source.length <= 0)
      s = '[mysqld]\n' + makeConfigLine(uname) + '\n';
    else
      s = cnf.source + '\n[mysqld]\n' + makeConfigLine(uname) + '\n';
  } else {
    s = cnf.source.substring(0, cnf.sectionend) +
      makeConfigLine(uname) + '\n\n' +
      cnf.source.substring(cnf.sectionend, cnf.source.length);
  }
  return write(ado, cnf.file, toCRLF(s), false);
}

var INSTALL_PLUGIN_SQL = "INSTALL PLUGIN transactd SONAME 'transactd.dll';";
function installPlugin(bin, rootuser, password) {
  var ret = runMySQLBinary(fso.BuildPath(bin.dir, 'bin\\mysql.exe'),
    '-e "' + INSTALL_PLUGIN_SQL + '"', rootuser, password);
  var succeed = ret[0];
  if (! succeed) {
    WScript.Echo('\nRun command FAILED.');
    WScript.Echo(fixMySQLErrorMessage(ret[2]));
  }
  return succeed;
}

function doInstall(td_ver, bin, plg, rootuser, password, needConfigure, unamehosts, cnf) {
  WScript.StdOut.Write('uninstalling plugin... ');
  var ret = uninstallPlugin(bin, rootuser, password);
  if (! ret)
    return false;
  ret = deletePluginRow(bin, rootuser, password);
  if (! ret)
    return false;
  WScript.Echo('done.');
  WScript.StdOut.Write('download zip from bizstation.jp... ');
  var zip_path = downloadZip(makeURL(bin, td_ver));
  if (zip_path.length <= 0)
    return false;
  WScript.Echo('done.');
  WScript.StdOut.Write('extract zip ... ');
  var tmp_dir = extractPluginZip(zip_path);
  if (tmp_dir.length <= 0)
    return false;
  WScript.Echo('done.');
  WScript.Echo('copying files... ');
  ret = copyPluginFiles(tmp_dir, plg.dir, td_ver);
  if (! ret)
    return false;
  WScript.Echo('done.');
  if (needConfigure) {
    WScript.StdOut.Write('set accessible hosts... ');
    ret = setAccessibleHosts(bin, rootuser, password, unamehosts[0], unamehosts[1]);
    if (! ret)
      return false;
    WScript.Echo('done.');
    WScript.StdOut.Write('set transactd_hostcheck_username... ');
    if (! cnf.exists)
      ret = createConfigFile(cnf, unamehosts[0]);
    else if (cnf.start >= 0)
      ret = replaceConfig(cnf, unamehosts[0]);
    else
      ret = addConfig(cnf, unamehosts[0]);
    if (! ret)
      return false;
    WScript.Echo('done.');
  }
  WScript.StdOut.Write('installing plugin... ');
  ret = installPlugin(bin, rootuser, password);
  if (! ret)
    return false;
  WScript.Echo('done.');
  return true;
}

//
//  main procedures
//

function exitWait(code) {
  if (userInterface)
  { 
    WScript.StdOut.Write('Press enter to exit ...');
    WScript.StdIn.ReadLine();
  }
  WScript.Quit(code);
}

function quitError(e) {
  WScript.Echo('');
  WScript.Echo('  ***  PLUGIN INSTALL FAILED  ***');
  if (typeof e != 'undefined')
    WScript.StdErr.Write(e.name + ': ' + e.message);
  WScript.Echo('');
  exitWait(2);
}

function quitCancel() {
  WScript.Echo('');
  WScript.Echo('  ***  PLUGIN INSTALL CANCELED  ***');
  WScript.Echo('');
  exitWait(1);
}
var userInterface = true;
function install( username, passwd , td_username , accessClass) {
  WScript.Echo('');
  WScript.Echo('Start MySQL/MariaDB server before install Transactd plugin.');
  WScript.Echo('');
  if (userInterface)
  {
    var pre_confirm = function(){ WScript.StdOut.Write('Install now? [Y/N(yes/no)]:'); };
    var confirm = confirmYN(pre_confirm);
    if (confirm == CONFIRM_NO)
      return false;
  }
  WScript.Echo('\n');
  WScript.Echo('[1] Search database and get information');
  WScript.Echo('----------------------------------------');
  var bin = detectDB();
  if (bin === false)
    quitCancel();
  bin = getInfo(bin);
  if (bin == false)
    quitError();
  WScript.Echo('done. [' +bin.product + '-' + bin.version + ' ' + bin.bit + ']');
  var td_ver = getLatestVersion();
  if (td_ver.length <= 0)
    quitError();
  WScript.Echo('\n');
  WScript.Echo('[2] Input username and password');
  WScript.Echo('----------------------------------------');
  var rootuser = username;
  var password = passwd;
  if (userInterface)
  {
    var userpass = inputUserPassword(bin);
    rootuser = userpass[0];
    password = userpass[1];
  }
  WScript.Echo('\n');
  WScript.Echo('[3] Check configurations');
  WScript.Echo('----------------------------------------');
  var plg = checkPluginInstallation(bin, rootuser, password);
  var cnf = checkConfigFile(bin);
  if (cnf.file.length <= 0)
    quitError();
  var needConfigure = cnf.start < 0 || cnf.value.length <= 0;
  var unamehosts = [];
  WScript.echo("needConfigure = " + needConfigure);
  if (needConfigure)
    unamehosts = inputConfigurations(cnf, td_username, accessClass);
  WScript.Echo('\n');
  WScript.Echo('[4] Confirm Installation');
  WScript.Echo('----------------------------------------');
  var ret = true;
  ret = confirmInstallation(td_ver, bin, plg, needConfigure, unamehosts, cnf);
  if (!ret)
    quitCancel();
  WScript.Echo('\n');
  WScript.Echo('[5] Install');
  WScript.Echo('----------------------------------------');
  ret = doInstall(td_ver, bin, plg, rootuser, password, needConfigure, unamehosts, cnf);
  if (!ret)
    quitError();
  return true;
}

function main() {
  userInterface = (WScript.Arguments.length != 4)
  var username = "";
  var passwd="";
  var td_username="";
  var accessClass="";
  if (!userInterface)
  {
    username = WScript.Arguments(0);
    passwd = WScript.Arguments(1);
    td_username = WScript.Arguments(2);
    accessClass = WScript.Arguments(3);
  }
  if (WScript.Arguments.length <= 0) {
    var cmd = '/c ""' + WScript.ScriptFullName + '" privileged"';
    shapp.ShellExecute('cmd.exe', cmd, '', 'runas');
    WScript.Quit(2);
  } else {
    if (! install( username, passwd , td_username , accessClass))
      quitError();
  }
}

try {
  main();
  WScript.Echo('');
  WScript.Echo('  ===  PLUGIN INSTALL FINISHED!  ===');
  WScript.Echo('');
  exitWait(0);
} catch (e) {
  quitError(e);
}
