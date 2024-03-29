#!/bin/bash

######################################################################
# A script to create some self signed certificates for the demo system
######################################################################

#
# Ensure that we are in the folder containing this script
#
cd "$(dirname "${BASH_SOURCE[0]}")"
mkdir -p certs
cd certs
set -e

#
# Point to the OpenSSL configuration file
#
case "$(uname -s)" in

  Darwin)
    export OPENSSL_CONF='/System/Library/OpenSSL/openssl.cnf'
 	;;

  MINGW64*)
    export OPENSSL_CONF='C:/Program Files/Git/usr/ssl/openssl.cnf';
    export MSYS_NO_PATHCONV=1;
	;;

  Linux*)
    export OPENSSL_CONF='/usr/lib/ssl/openssl.cnf';
esac

#
# Certificate properties
#
ROOT_CERT_FILE_PREFIX='curity.local.ca'
ROOT_CERT_DESCRIPTION='Self Signed CA for curity.local'
SSL_CERT_FILE_PREFIX='curity.local.ssl'
SSL_CERT_PASSWORD='Password1'
WILDCARD_DOMAIN_NAME='*.curity.local'

#
# Create the root certificate public + private key
#
openssl genrsa -out $ROOT_CERT_FILE_PREFIX.key 2048
echo '*** Successfully created Root CA key'

#
# Create the public key root certificate file
#
openssl req -x509 \
            -new \
            -nodes \
            -key $ROOT_CERT_FILE_PREFIX.key \
            -out $ROOT_CERT_FILE_PREFIX.pem \
            -subj "/CN=$ROOT_CERT_DESCRIPTION" \
            -reqexts v3_req \
            -extensions v3_ca \
            -sha256 \
            -days 365
echo '*** Successfully created Root CA'

#
# Create the SSL key
#
openssl genrsa -out $SSL_CERT_FILE_PREFIX.key 2048
echo '*** Successfully created SSL key'

#
# Create the certificate signing request file
#
openssl req \
            -new \
			-key $SSL_CERT_FILE_PREFIX.key \
			-out $SSL_CERT_FILE_PREFIX.csr \
			-subj "/CN=$WILDCARD_DOMAIN_NAME"
echo '*** Successfully created SSL certificate signing request'

#
# Create the SSL certificate and private key
#
openssl x509 -req \
			-in $SSL_CERT_FILE_PREFIX.csr \
			-CA $ROOT_CERT_FILE_PREFIX.pem \
			-CAkey $ROOT_CERT_FILE_PREFIX.key \
			-CAcreateserial \
			-out $SSL_CERT_FILE_PREFIX.pem \
			-sha256 \
			-days 36 \
      -extfile server.ext
echo '*** Successfully created SSL certificate'
