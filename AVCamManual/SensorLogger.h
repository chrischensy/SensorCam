//
//  SensorLogger.h
//  iOSSensorsLogger
//
//  Created by Zhiping Jiang on 14-9-29.
//  Copyright (c) 2014年 Zhiping Jiang. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
@interface SensorLogger : NSObject<CLLocationManagerDelegate>

@property BOOL logSwitch;

@property BOOL rawAccEnable;
@property BOOL rawGyroEnable;
@property BOOL rawMagEnable;
@property BOOL deviceMotionEnable;

@property double accSamplingRate;
@property double gyroSamplingRate;
@property double magSamplingRate;
@property double deviceMotionSamplingRate;

@property CMMotionManager * motionManager;
@property NSMutableArray * sensorLoggerArray;
@property NSMutableArray * accTimestampArray;
@property NSMutableArray * gyroTimestampArray;
@property NSMutableArray * magTimestampArray;
@property NSMutableArray * attTimestampArray;

@property CLLocationManager * locationManager;

+ (id) getInstance;

-(void) setSamlingRateToAcc:(double)accInterval toGyro:(double)gyroInterval toMag:(double)magInterval toAtt:(double)attInterval;

-(void) startSensor;

-(void) stopSensor;

-(void) startLogging;

-(void) stopLogging;

-(float) avgAccSamplingRate;

-(float) avgGyroSamplingRate;

-(float) avgMagSamplingRate;

-(float) avgAttSamplingRate;

-(void) writeToFile:(NSString *)Prefix;

@end
