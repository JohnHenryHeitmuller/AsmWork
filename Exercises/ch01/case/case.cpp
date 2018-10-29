#include <stdio.h>
#include <string.h>

void toupper( char *str)
{
	int i=0;

	while(str[i])
	{	str[i++] ^= 0x20; 
	}
}

void tolower( char *str)
{
	int i=0;

	while(str[i])
	{	str[i++] |= 0x20; 
	}
}

int CharToInt( char *str)
{
	int len=0,
		rtn=0,
		powerof10=1;

	while(str[len])
	{	len++;
	}

	while(len--)
	{	rtn += (str[len] - 0x30) * powerof10;
		powerof10 *= 10;

	}
	return(rtn);
}


int main( int argc, char **argv)
{
	char str[20] = {"john\0"};
	int i;

	toupper(str);
	printf( "Upper: %s\n", str);
	tolower(str);
	printf( "Lower: %s\n\n", str);

	strcpy( str, "" );
	i = CharToInt(str);
	printf( "int: %s = %d\n",str, i);

	strcpy( str, "0" );
	i = CharToInt(str);
	printf( "int: %s = %d\n",str, i);

	strcpy( str, "65535" );
	i = CharToInt(str);
	printf( "int: %s = %d\n",str, i);

	strcpy( str, "4294967295" );
	i = CharToInt(str);
	printf( "int: %s = %d\n",str, i);

	return(0);
}