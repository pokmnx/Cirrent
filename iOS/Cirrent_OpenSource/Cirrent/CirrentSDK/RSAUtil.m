//
//  RSAUtil.m
//  Cirrent
//
//  Created by P on 1/29/17.
//  Copyright © 2017 PSIHPOK. All rights reserved.
//

#import "RSAUtil.h"
#include <openssl/bio.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <openssl/err.h>
#include <openssl/ssl.h>

@implementation RSAUtil

+(RSA*) createPublicRSA:(char*) public_key {
    RSA *rsa    = NULL;
    BIO *keybio = NULL;
    
    // Get a pointer to the BIO structure
    keybio = BIO_new_mem_buf(public_key, -1);
    
    // Return NULL if BIO_new_mem_buf returned error.
    if (keybio == NULL)
    {
        return(NULL);
    }
    
    // Get a pointer to the RSA structure
    rsa = PEM_read_bio_RSA_PUBKEY(keybio, &rsa, NULL, NULL);
    BIO_free_all(keybio);
    
    return(rsa);
}

+(RSA*) createPrivateRSA:(char*) private_key{
    RSA *rsa    = NULL;
    BIO *keybio = NULL;
    
    // Get a pointer to the BIO structure
    keybio = BIO_new_mem_buf(private_key, -1);
    
    // Return NULL if BIO_new_mem_buf returned error.
    if (keybio == NULL)
    {
        return(NULL);
    }
    
    // Get a pointer to the RSA structure
    rsa = PEM_read_bio_RSAPrivateKey(keybio, &rsa, NULL, NULL);
    
    // Log an error if PEM_read_bio_RSAPrivateKey returned NULL
    if (rsa == NULL)
    {
        
    }
    
    BIO_free_all(keybio);
    
    return(rsa);
}

+(NSData*) encryptString:(NSString*) data withKey:(NSString*) key {
    
    RSA *rsa = NULL;
    
    const char* dataBuffer = [data UTF8String];
    unsigned char* buffer = malloc(sizeof(char) * strlen(dataBuffer));
    memcpy(buffer, dataBuffer, sizeof(char) * strlen(dataBuffer));
    
    int buffer_len = (int) (sizeof(char) * strlen(dataBuffer));
    const char* keyBuffer = [key UTF8String];
    char* public_key = malloc(sizeof(char) * strlen(keyBuffer));
    memcpy(public_key, keyBuffer, sizeof(char) * strlen(keyBuffer));
    
    unsigned char* encrypt_buffer;
    
    rsa = [RSAUtil createPublicRSA:public_key];
    if (rsa == NULL) {
        return NULL;
    }
    
    int bufferSize = RSA_size(rsa) + 1;
    
    encrypt_buffer = malloc(bufferSize);
    if (encrypt_buffer == NULL) {
        return NULL;
    }
    else {
        int result = RSA_public_encrypt(buffer_len, buffer, encrypt_buffer, rsa, RSA_PKCS1_OAEP_PADDING);
        if (result > 0) {
            encrypt_buffer[result] = '\0';
            
            NSData* encData = [NSData dataWithBytes:encrypt_buffer length:result];
            
            return encData;
        }
        else {
            SSL_load_error_strings();
            unsigned long e = ERR_get_error();
            
            NSString* errorStr = [NSString stringWithFormat:@"%s, %s, %s", ERR_lib_error_string(e),
                                  ERR_func_error_string(e),
                                  ERR_reason_error_string(e)];
            NSLog(@"%@", errorStr);
            RSA_free(rsa);
            return NULL;
        }
    }
}

+(NSString*) decryptString:(NSData*) data withKey:(NSString*) key {
    unsigned char* enc_buffer;
    unsigned char* decrypt_buffer;
    
    RSA *rsa = NULL;
    
    const char* dataBuffer = [data bytes];
    NSUInteger size = [data length];
    enc_buffer = malloc(size);
    memcpy(enc_buffer, dataBuffer, size);
    
    const char* keyBuffer = [key UTF8String];
    char* private_key = malloc(sizeof(char) * strlen(keyBuffer));
    memcpy(private_key, keyBuffer, sizeof(char) * strlen(keyBuffer));
    printf("private key - %s\n", private_key);
    
    rsa = [RSAUtil createPrivateRSA:private_key];
    decrypt_buffer = malloc(RSA_size(rsa) + 1);
    
    if (rsa == NULL) {
        return NULL;
    }
    else {
        int result = RSA_private_decrypt(RSA_size(rsa), enc_buffer, decrypt_buffer, rsa, RSA_PKCS1_OAEP_PADDING);
        
        if (result > 0) {
            decrypt_buffer[result] = '\0';
            NSString* result = [NSString stringWithFormat:@"%s", decrypt_buffer];
            RSA_free(rsa);
            return result;
        }
        else {
            SSL_load_error_strings();
            unsigned long e = ERR_get_error();
            NSString* errStr = [NSString stringWithFormat:@"%s, %s, %s", ERR_lib_error_string(e), ERR_func_error_string(e),ERR_reason_error_string(e)];
            
            RSA_free(rsa);
            return errStr;
        }
    }
}


@end
