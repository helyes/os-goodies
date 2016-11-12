
# Crypt files

Encrypts and decrypts single file by concatenating a password input by the user and a password file content.
Utilizes [gnu gpg utility](http://brewformulas.org/Gnupg) <br>

Ideal to use for encrypting sensitive files before uploading to cloud. <br>
I personally use it for dropbox backups. I sync a directory - contains my personal documents -  encrypted by [encfs6](https://vgough.github.io/encfs) with dropbox. Once in a while I zip the decrypted end of encfs6 link, zip and encrypt it with this script then upload the encrypted file to amazon clouddrive as a backup.

## Encryption method

```sh
gpg --yes --batch --passphrase=<user inut + password file content> --require-secmem --symmetric \
    --compress-algo ZIP --compress-level 9 \
    --cipher-algo AES256 --s2k-cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-mode 3 --s2k-count 33554432 \
    <file to encrypt>
```

For a quick explanation of the parameters see the script itself. <br>
The [gnupg man page](https://www.gnupg.org/documentation/manpage.html) includes more details

## Prerequisites

On mac install gnupg via brew

```sh
 brew install gnupg gpg2                                                        
```

Check version
```sh
$ brew info gnupg
gnupg: stable 1.4.21 (bottled)
GNU Pretty Good Privacy (gpg) package
https://www.gnupg.org/
...
$ brew info gpg2
gnupg2: stable 2.0.30 (bottled)
GNU Privacy Guard: a free gpg replacement
https://www.gnupg.org/
```

## Usage

### Encrypting file

Running the script below will encrypt `fixtures/Private-file.txt` as `fixtures/Private-file.txt.gpg` using the concatenation of a user input password and the content of `fixtures/password.file.pwd`.

```sh
$ ./crypt-file.sh fixtures/password.file.pwd e fixtures/Private-file.txt
Enter password: *************
PWD RAW: typedpassword
Encrypting fixtures/Private-file.txt
Using password: typedpassword-thisshouldbearelativelylong~1kbrandomstring
```

The encrypted file appears in `./fixtures` directory after a the script ran
```
$ ls -l fixtures/
total 24
-rw-r--r--  1 andras  staff  3503 13 Nov 08:20 Private-file.txt
-rw-r--r--  1 andras  staff  1489 13 Nov 08:33 Private-file.txt.gpg
-rw-r--r--  1 andras  staff    44 13 Nov 08:22 password.file.pwd
```


### Decrypting file

Running the script below will decrypt `/tmp/Private-file.txt.gpg` as `/tmp/Private-file.txt` using the concatenation of a user typed password and the content of `fixtures/password.file.pwd`.

```sh
$ ./crypt-file.sh fixtures/password.file.pwd d /tmp/Private-file.txt.gpg d
Enter password: *************
PWD RAW: typedpassword
Decrypting /tmp/Private-file.txt.gpg
gpg: AES256 encrypted data
gpg: encrypted with 1 passphrase
```

`Private-file.txt` created and its content is identical to the original, pre encrypt file
```sh
$ ls -l /tmp/Private-file.*
-rw-r--r--  1 andras  wheel  3503 13 Nov 09:03 /tmp/Private-file.txt
-rw-r--r--  1 andras  wheel  1489 13 Nov 08:53 /tmp/Private-file.txt.gpg
```

```
$ diff fixtures/Private-file.txt /tmp/Private-file.txt
```
