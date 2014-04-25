- (NSString*) uploadKeyBundle:(NSString*)key_bundle consumer:(Principal*)consumer {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:uploadKeyBundle:consumer: called.");
        
        if (_file_store == nil || key_bundle == nil || consumer == nil)
            return @"File-store, key-bundle or consumer are not set";
    
    // Build any meta-data we need to upload the key-bundle via our file-store's API.
    NSString* filename = [[NSString alloc] initWithFormat:@"%s.%s", [consumer.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kFSKeyBundleExt];
    
    // Build this consumer's personal bucket.
    NSNumber* nonce = [_file_store objectForKey:[NSString stringWithCString:kFSKeyNonce encoding:[NSString defaultCStringEncoding]]];
    NSString* bucket = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%d", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [nonce intValue]]];
    
    // Depending on the file-store type, add additional path elements.
    NSString* err_msg = nil;
    if ([PersonalDataController isFileStoreServiceAmazonS3:_file_store]) {
        if (kDebugLevel > 1)
            NSLog(@"PersonalDataController:uploadKeyBundle: using S3 as file store.");
        
        // S3 simply uses the bucket and filename.
        err_msg = [self amazonS3Upload:key_bundle bucket:bucket filename:filename];
        return err_msg;
    } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_file_store]) {
        if (kDebugLevel > 1)
            NSLog(@"PersonalDataController:uploadKeyBundle: using S3 as file store.");
        
        // Drive stores stuff in the root folder SLS, but that's accounted for in googleDriveUpload:.
        err_msg = [self googleDriveUpload:key_bundle bucket:bucket filename:filename];
        return err_msg;
    } else {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Unknown service: %s", [[_file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        NSLog(@"PersonalDataController:uploadKeyBundle: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return err_msg;
    }
    
    return nil;
}

- (NSString*) uploadHistoryLog:(NSString*)history_log policy:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"PersonalDataController:uploadHistoryLog:policy: called.");
        
        if (_file_store == nil || history_log == nil || policy == nil)
            return @"File_store, history-log or policy are not set";
    
    // Build any meta-data we need to upload the key-bundle via our file-store's API.
    NSString* filename = [NSString stringWithFormat:@"%s", kFSHistoryLogFile];
    
    // Build this policy's personal bucket.
    NSNumber* nonce = [_file_store objectForKey:[NSString stringWithCString:kFSKeyNonce encoding:[NSString defaultCStringEncoding]]];
    NSString* bucket = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%s%d", [_identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [policy cStringUsingEncoding:[NSString defaultCStringEncoding]], [nonce intValue]]];
    
    // Depending on the file-store type, add additional path elements.
    NSString* err_msg = nil;
    if ([PersonalDataController isFileStoreServiceAmazonS3:_file_store]) {
        if (kDebugLevel > 1)
            NSLog(@"PersonalDataController:uploadHistoryLog: using S3 as file store.");
        
        // S3 simply uses the bucket and filename.
        err_msg = [self amazonS3Upload:history_log bucket:bucket filename:filename];
        return err_msg;
    } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_file_store]) {
        if (kDebugLevel > 1)
            NSLog(@"PersonalDataController:uploadHistoryLog: using Drive as file store.");
        
        // Drive stores stuff in the root folder SLS, but that's accounted for in googleDriveUpload:.
        err_msg = [self googleDriveUpload:history_log bucket:bucket filename:filename];
        return err_msg;
    } else {
        NSString* err_msg = [[NSString alloc] initWithFormat:@"Unknown service: %s", [[_file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        NSLog(@"PersonalDataController:uploadHistoryLog: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return err_msg;
    }
    
    return nil;
}

