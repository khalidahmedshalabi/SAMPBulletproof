/*
 *            DUtils functions 1.10
 *       (c) Copyright 2006-2007 by DracoBlue
 *
 * @author    : DracoBlue (http://dracoblue.com)
 * @date      : 8th April 2006
 * @update    : 12th July 2007
 *
 * This file is provided as is (no warranties).
 *
 */

#if defined _dutils_included
  #endinput
#endif

#define _dutils_included
#pragma library dutils

#define MAX_STRING 255

new PRIVATE_Last_Money[MAX_PLAYERS];

/*
 * First version released by mike, this one created by DracoBlue
 * Has also a fix to use "-" and "+" in the beginning of the number.
 */
stock isNumeric(const string[]) {
	new length=strlen(string);
	if (length==0) return false;
	for (new i = 0; i < length; i++) {
		if (
		(string[i] > '9' || string[i] < '0' && string[i]!='-' && string[i]!='+') // Not a number,'+' or '-'
		|| (string[i]=='-' && i!=0)                                             // A '-' but not at first.
		|| (string[i]=='+' && i!=0)                                             // A '+' but not at first.
		) return false;
	}
	if (length==1 && (string[0]=='-' || string[0]=='+')) return false;
	return true;
}

/*
 * Originally created by mabako, tuned by DracoBlue
 */
stock mktime(hour,minute,second,day,month,year) {
	new timestamp2;

	timestamp2 = second + (minute * 60) + (hour * 3600);

	new days_of_month[12];

	if ( ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0) ) {
			days_of_month = {31,29,31,30,31,30,31,31,30,31,30,31}; // Schaltjahr
		} else {
			days_of_month = {31,28,31,30,31,30,31,31,30,31,30,31}; // keins
		}
	new days_this_year = 0;
	days_this_year = day;
	if(month > 1) { // No January Calculation, because its always the 0 past months
		for(new i=0; i<month-1;i++) {
			days_this_year += days_of_month[i];
		}
	}
	timestamp2 += days_this_year * 86400;

	for(new j=1970;j<year;j++) {
		timestamp2 += 31536000;
		if ( ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0) )  timestamp2 += 86400; // Schaltjahr + 1 Tag
	}

	return timestamp2;
}


/**
 *  Return if a Email is valid or not
 *  @param   value
 */
stock ValidEmail(email[]) {
  new len=strlen(email);
  new cstate=0;
  new i;
  for(i=0;i<len;i++) {
    if ((cstate==0 || cstate==1) && (email[i]>='A' && email[i]<='Z') || (email[i]>='a' && email[i]<='z')  || (email[i]=='.')  || (email[i]=='-')  || (email[i]=='_'))
    {
    } else {
       // Ok no A..Z,a..z,_,.,-
       if ((cstate==0) &&(email[i]=='@')) {
          // its an @ after the name, ok state=1;
          cstate=1;
       } else {
          // Its stuff which is not allowed
          return false;
       }
    }
  }
  if (cstate<1) return false;
  if (len<6) return false;
  // A toplevel domain has only 3 to 4 signs :-)
  if ((email[len-3]=='.') || (email[len-4]=='.') || (email[len-5]=='.')) return true;
  return false;
}

/**
 *  Return a timestamp
 */
stock Time() {
  new hour,minute,second;
  new year, month,day;
  gettime(hour, minute, second);
  getdate(year, month, day);
  return mktime(hour,minute,second,day,month,year);
}


/**
 *  Return a timestamp
 */
stock Now() {
  new hour,minute,second;
  new year, month,day;
  gettime(hour, minute, second);
  getdate(year, month, day);
  return mktime(hour,minute,second,day,month,year);
}


/**
 *  Return the value of an hex-string
 *  @param string
 */
stock HexToInt(string[]) {
  if (string[0]==0) return 0;
  new i;
  new cur=1;
  new res=0;
  for (i=strlen(string);i>0;i--) {
    if (string[i-1]<58) res=res+cur*(string[i-1]-48); else res=res+cur*(string[i-1]-65+10);
    cur=cur*16;
  }
  return res;
}

/**
 *  Return the int as string
 *  @param   number
 */
stock IntToHex(number)
{
	new m=1;
	new depth=0;
	while (number>=m) {
		m = m*16;
		depth++;
	}
	depth--;
	new str[MAX_STRING];
	for (new i = depth; i >= 0; i--)
	{
		str[i] = ( number & 0x0F) + 0x30; // + (tmp > 9 ? 0x07 : 0x00)
		str[i] += (str[i] > '9') ? 0x07 : 0x00;
		number >>= 4;
	}
	str[8] = '\0';
	return str;
}

/**
 *  Return the string as int
 *  @param   string
 */
stock StrToInt(string[]) {
  return strval(string);
}

/**
 *  Return the value as string
 *  @param   value
 */
stock IntToStr(value) {
  new tmp[MAX_STRING];
  valstr(tmp, value);
  return tmp;
}

/**
 *  Return the truncated value
 *  @param   Float:value
 */
stock trunc(Float:value) {
	return floatround(value,floatround_floor);
}

/**
 *  Sets money for player
 *  @param   playerid
 *           howmuch
 */
stock SetPlayerMoney(playerid,howmuch) {
  PRIVATE_Last_Money[playerid]=howmuch;
  GivePlayerMoney(playerid,howmuch-GetPlayerMoney(playerid));
}

/**
 *  Copies a file (Source file won't be deleted!)
 *  @param   oldname
 *           newname
 *  @requires WINDOWS
 */
stock fcopy(oldname[],newname[]) {
	new File:ohnd,File:nhnd;
	if (!fexist(oldname)) return false;
	ohnd=fopen(oldname,io_read);
	nhnd=fopen(newname,io_write);
	new buf2[1];
	new i;
	for (i=flength(ohnd);i>0;i--) {
		fputchar(nhnd, fgetchar(ohnd, buf2[0],false),false);
	}
	fclose(ohnd);
	fclose(nhnd);
	return true;
}


/**
 *  Copies a textfile (Source file won't be deleted!)
 *  @param   oldname
 *           newname
 */
stock fcopytextfile(oldname[],newname[]) {
	new File:ohnd,File:nhnd;
	if (!fexist(oldname)) return false;
	ohnd=fopen(oldname,io_read);
	nhnd=fopen(newname,io_write);
	new tmpres[MAX_STRING];
	while (fread(ohnd,tmpres)) {
		StripNewLine(tmpres);
		format(tmpres,sizeof(tmpres),"%s\r\n",tmpres);
		fwrite(nhnd,tmpres);
	}
	fclose(ohnd);
	fclose(nhnd);
	return true;
}


/**
 *  Renames a file (Source file will be deleted!)
 *  @param   oldname
 *           newname
 *  @requires WINDOWS (because fcopy does)
 */
stock frename(oldname[],newname[]) {
    if (!fexist(oldname)) return false;
    fremove(newname);
    if (!fcopy(oldname,newname)) return false;
    fremove(oldname);
    return true;
}

/**
 *  Renames a file (Source file will be deleted!)
 *  @param   oldname
 *           newname
 */
stock frenametextfile(oldname[],newname[]) {
    if (!fexist(oldname)) return false;
    fremove(newname);
    if (!fcopytextfile(oldname,newname)) return false;
    fremove(oldname);
    return true;
}

/**
 *  Strips Newline from the end of a string.
 *  Idea: Y_Less, Bugfixing (when length=1) by DracoBlue
 *  @param   string
 */
stock StripNewLine(string[])
{
	new len = strlen(string);
	if (string[0]==0) return ;
	if ((string[len - 1] == '\n') || (string[len - 1] == '\r')) {
		string[len - 1] = 0;
		if (string[0]==0) return ;
		if ((string[len - 2] == '\n') || (string[len - 2] == '\r')) string[len - 2] = 0;
	}
}

/**
 *  Copies items from one array/string into return.
 *  @param   source
 *           index (where to start, 0 is first)
 *           numbytes (how much)
 */
ret_memcpy(source[],index=0,numbytes) {
	new tmp[MAX_STRING];
	new i=0;
	tmp[0]=0;
	if (index>=strlen(source)) return tmp;
	if (numbytes+index>=strlen(source)) numbytes=strlen(source)-index;
	if (numbytes<=0) return tmp;
	for (i=index;i<numbytes+index;i++) {
		tmp[i-index]=source[i];
		if (source[i]==0) return tmp;
	}
	tmp[numbytes]=0;
	return tmp;
}

/**
 *  Copies items from one array/string into another.
 *  @param   dest
 *           source
 *           count
 */
stock copy(dest[],source[],count) {
	dest[0]=0;
	if (count<0) return false;
	if (count>strlen(source)) count=strlen(source);
	new i=0;
	for (i=0;i<count;i++) {
		dest[i]=source[i];
		if (source[i]==0) return true;
	}
	dest[count]=0;
	return true;
}


/**
 *  Deletes the first 'count' items of a array/string
 *  @param   string[]
 *           count
 */
stock delete(string[],count) {
	new tmp[MAX_STRING];
	tmp[0]=0;
	if (count<=0) {
		format(tmp,sizeof(tmp),"%s",string);
		return tmp;
	}
	tmp=ret_memcpy(string,count,strlen(string));
	return tmp;
}

/**
 *  Sets a string's value to source.
 *  @param   dest
 *           source
 *           count
 */
stock set(dest[],source[]) {
	new count = strlen(source);
	new i=0;
	for (i=0;i<count;i++) {
		dest[i]=source[i];
	}
	dest[count]=0;
}

/**
 *  Checks wether two strings are equal (case insensetive)
 *  @param   str1
 *           str2
 */
stock equal(str1[],str2[],bool:ignorecase) {
    if (strlen(str1)!=strlen(str2)) return false;
    if (strcmp(str1,str2,ignorecase)==0) return true;
    return false;
}

/**
 *  Returns an element of a string splitted by ' ', default index is 0.
 *  @param   string
 *           index
 */
stock strtok(const string[], &index,seperator=' ')
{
	new length = strlen(string);
	new offset = index;
	new result[MAX_STRING];
	while ((index < length) && (string[index] != seperator) && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}

	result[index - offset] = EOS;
	if ((index < length) && (string[index] == seperator))
	{
		index++;
	}
	return result;
}

stock mod(up,down) {
  return up-(floatround((up/down),floatround_floor))*down;
}

stock div(up,down) {
  return (floatround((up/down),floatround_floor));
}

/**
 *  Returns a hashed value in adler32 as int
 *  @param   buf
 */
stock num_hash(buf[])
 {
	new length=strlen(buf);
    new s1 = 1;
    new s2 = 0;
    new n;
    for (n=0; n<length; n++) {
       s1 = (s1 + buf[n]) % 65521;
       s2 = (s2 + s1)     % 65521;
    }
    return (s2 << 16) + s1;
 }

/**
 *  Returns a hashed value in adler32 as string
 *  @param   buf
 */
stock hash(str2[]) {
   new tmpdasdsa[MAX_STRING];
   tmpdasdsa[0]=0;
   valstr(tmpdasdsa,num_hash(str2));
   return tmpdasdsa;
}

/**
 *  Returns a string which has 'newstr' where 'trg' was before
 *  @param   trg
 *           newstr
 *           src
 */
stock strreplace(trg[],newstr[],src[]) {
    new f=0;
    new s1[MAX_STRING];
    new tmp[MAX_STRING];
    format(s1,sizeof(s1),"%s",src);
    f = strfind(s1,trg);
    tmp[0]=0;
    while (f>=0) {
        strcat(tmp,ret_memcpy(s1, 0, f));
        strcat(tmp,newstr);
        format(s1,sizeof(s1),"%s",ret_memcpy(s1, f+strlen(trg), strlen(s1)-f));
        f = strfind(s1,trg);
    }
    strcat(tmp,s1);
    return tmp;
}

/**
 *  Returns the string with lowercase
 *  @param   txt
 */
stock strlower(txt[]) {
	new tmp[MAX_STRING];
	tmp[0]=0;
	if (txt[0]==0) return tmp;
	new i=0;
	for (i=0;i<strlen(txt);i++) {
		tmp[i]=tolower(txt[i]);
	}
	tmp[strlen(txt)]=0;
	return tmp;
}

/**
 *  Returns the string with uppercase
 *  @param   txt
 */
stock strupper(txt[]) {
	new tmp[MAX_STRING];
	tmp[0]=0;
	if (txt[0]==0) return tmp;
	new i=0;
	for (i=0;i<strlen(txt);i++) {
		tmp[i]=toupper(txt[i]);
	}
	tmp[strlen(txt)]=0;
	return tmp;
}
