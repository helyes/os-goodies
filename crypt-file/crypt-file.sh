#!/bin/bash -e

################################################################################################################
# Encrypt / decrypt single file by concatenating a password input by the user and a password file content.     #
# On mac install gnupg via brew: "brew install gpg1"                                                           #
#                                                                                                              #
# Parameters used for encryption:                                                                              #
#                                                                                                              #
# yes - Assume "yes" on most questions                                                                         #
# batch - Never ask, do not allow interactive commands                                                         #
# passphrase - Use the string as the passphrase. This can only be used if only one passphrase is supplied      #
# require-secmem - Refuse to run if GnuPG cannot get secure memory                                             #
# symmetric - Encrypt with a symmetric cipher using a passphrase. The default is AES128, --cipher-algo option  #
#                                                                                                              #
# compress-algo ZIP - The compression algorithm. Check available compression algorithms by gpg --version       #
# compress-level 9 - Compression level                                                                         #
#                                                                                                              #
# cipher-algo - Use name as cipher algorithm. Running gpg --version yields a list of supported algo-rithms     #
# s2k-cipher-algo AES256 - the cipher algorithm used to protect secret keys                                    #
# s2k-digest-algo SHA512 - the digest algorithm used to mangle the passphrases                                 #
# s2k-mode 3 - Selects how passphrases are mangled. 3 iterates it --s2k-count number of times                  #
# s2k-count 33554432 - How many times the passphrase mangling is repeated. Valid range 1024 to 65011712        #
#                                                                                                              #
# 17:12 $ gpg --version                                                                                        #
# gpg (GnuPG) 1.4.21                                                                                           #
# Copyright (C) 2015 Free Software Foundation, Inc.                                                            #
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>                                #
# This is free software: you are free to change and redistribute it.                                           #
# There is NO WARRANTY, to the extent permitted by law.                                                        #
#                                                                                                              #
# Home: ~/.gnupg                                                                                               #
# Supported algorithms:                                                                                        #
# Pubkey: RSA, RSA-E, RSA-S, ELG-E, DSA                                                                        #
# Cipher: IDEA, 3DES, CAST5, BLOWFISH, AES, AES192, AES256, TWOFISH,                                           #
#         CAMELLIA128, CAMELLIA192, CAMELLIA256                                                                #
# Hash: MD5, SHA1, RIPEMD160, SHA256, SHA384, SHA512, SHA224                                                   #
# Compression: Uncompressed, ZIP, ZLIB, BZIP2                                                                  #
#                                                                                                              #                                          #
# Requires gnupg 1.4.X (will not work with v2.x.x versions)                                                    #
# Installing on macos                                                                                          #
# - brew install gpg1                                                                                          #
# - /usr/local/opt/gnupg@1.4/libexec/gpgbin  (add bin folder to path)                                          #
################################################################################################################

#Path to password file
PWDFILE=$1

#Encrypt (e) or decrypt (d)
COMMAND=$2

#The file to encrypt or decrypt
FILE=$3

unamestr=`uname`

if [[ "$unamestr" == 'Linux' ]]; then
  PLATFORM=linux
  echo "WARN: Script has not been tested on Linux"
elif [[ "$unamestr" == 'Darwin' ]]; then
  PLATFORM=osx
fi

function encrypt {
  echo "Encrypting $FILE"
  echo "Using password: $CONCATENATEDPWD"
  gpg --yes --batch --passphrase=$CONCATENATEDPWD --require-secmem --symmetric \
      --compress-algo ZIP --compress-level 9 \
      --cipher-algo AES256 --s2k-cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-mode 3 --s2k-count 33554432 \
      $FILE
}


function decrypt() {
  echo "Decrypting $FILE"
  # echo $CONCATENATEDPWD | gpg --batch --yes --passphrase-fd 0 $FILE
  echo $CONCATENATEDPWD | gpg --passphrase-fd 0 $FILE
}

function usage {
	echo
	echo "Usage : $0 <password file path> [e|d] <name of file>"
    echo
    echo "  Example:"
    echo "  Encrypting blah.txt: crypt-file pwd.txt e blah.txt"
    echo "  Decrypting blah.txt.gpg: crypt-file pwd.txt d blah.txt.gpg"
    exit;
}

if [[ -z "$PWDFILE" ]]; then
	echo "Password file not set"
	usage
fi

if [[ -z "$COMMAND" ]]; then
	echo "Command not set"
	usage
fi

if [[ -z "$FILE" ]]; then
	echo "File not set"
	usage
fi

FILEPWD=`cat $PWDFILE`

function readpassword {
   echo -e "Enter password: \c"
   unset PWD_RAW;
   while IFS= read -r -s -n1 pass; do
     if [[ -z $pass ]]; then
       echo
       break
     else
       echo -n '*'
       PWD_RAW+=$pass
     fi
   done
   echo "PWD RAW: $PWD_RAW"
   PWD=`echo $PWD_RAW | tr -d '\n'`
   CONCATENATEDPWD=${PWD}-${FILEPWD}
}

case "$COMMAND" in
  e) readpassword
     encrypt
     ;;
  d) readpassword
	 decrypt
     ;;
  *) echo "Unknown parameter: $COMMAND. Must use e or d"
     usage
     ;;
esac
