//
//  UIApplication+Authority.m
//  MYKitDemo
//
//  Created by sunjinshuai on 2018/3/14.
//  Copyright © 2018年 com.51fanxing. All rights reserved.
//

#import "UIApplication+Authority.h"
#import <CoreLocation/CoreLocation.h>
#import <Photos/Photos.h>
#import <Contacts/Contacts.h>
#import <AVFoundation/AVFoundation.h>
#import <EventKit/EventKit.h>

@implementation UIApplication (Authority)

#pragma mark - 权限查询
// Querying authorization does not request permission.
+ (BOOL)getApplicationLocationPermit {
    CLAuthorizationStatus status = [[CLLocationManager new] authorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

+ (BOOL)getApplicationAddressBookPermit {
    return [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusAuthorized;
}

+ (BOOL)getApplicationCameraPermit {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized;
}

+ (BOOL)getApplicationRemindersPermit {
    
    BOOL authorizationStatusAuthorized = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder] == EKAuthorizationStatusAuthorized;
    
    return authorizationStatusAuthorized;
}

+ (BOOL)getApplicationPhotosLibraryPermit {
    
    BOOL authorizationStatusAuthorized = [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized;
    
    return authorizationStatusAuthorized;
}

+ (void)getApplicationMicrophonePermitWithBlock:(CLPermissionBlock)block {
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        
        if (block) {
            block(granted);
        }
    }];
}

@end
