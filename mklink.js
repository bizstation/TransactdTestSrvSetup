/* mklink.js

   Copyright (C) 2016 BizStation Corp All rights reserved.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software 
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  
   02111-1307, USA.
*/

function main()
{
	if (WScript.Arguments.length < 2)
	{
		WScript.echo("Please specify filename target");
		return 1;
	}
	var filename = WScript.Arguments(0);
	var target = WScript.Arguments(1);
	var args = "";
	if (WScript.Arguments.length > 2)
		args = WScript.Arguments(2);
	var shell = new ActiveXObject('WScript.Shell');
	var shortCut = shell.CreateShortcut(filename)
	shortCut.TargetPath = target;
	shortCut.Arguments = args;
	shortCut.Save();
	return 0;
}

WScript.Quit(main());
