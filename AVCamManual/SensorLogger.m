//
//  SensorLogger.m
//  iOSSensorsLogger
//
//  Created by Zhiping Jiang on 14-9-29.
//  Copyright (c) 2014年 Zhiping Jiang. All rights reserved.
//

#import "SensorLogger.h"



@implementation SensorLogger

BOOL compassCalibrated = NO;

+(id) getInstance {
    static SensorLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[self alloc] init];
    });
    return logger;
}

-(id) init {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingHeading];
    self.motionManager = [[CMMotionManager alloc] init];
    self.sensorLoggerArray = [[NSMutableArray alloc] init];
    self.accTimestampArray = [[NSMutableArray alloc] init];
    self.gyroTimestampArray= [[NSMutableArray alloc] init];
    self.magTimestampArray = [[NSMutableArray alloc] init];
    
    self.accSamplingRate = 0.0;
    self.gyroSamplingRate = 0.0;
    self.magSamplingRate = 0.0;
    self.deviceMotionSamplingRate = 100.0;
    
    self.rawAccEnable = NO;
    self.rawGyroEnable = NO;
    self.rawMagEnable = NO;
    self.deviceMotionEnable = YES;
    
    self.logSwitch = NO;
    
    [self setSamlingRateToAcc:self.accSamplingRate toGyro:self.gyroSamplingRate toMag:self.magSamplingRate toAtt:self.deviceMotionSamplingRate];
    [self startSensor];
    
    return self;
}

-(void) locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
}

-(BOOL) locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    NSLog(@"calibration invoked");
    if (self.logSwitch == NO && compassCalibrated == NO) {
        compassCalibrated = YES;
        return YES;
    } else return NO;
}

-(void) setSamlingRateToAcc:(double)accRate toGyro:(double)gyroRate toMag:(double)magRate toAtt:(double)attRate {
    
    if (self.motionManager.isAccelerometerAvailable == YES) {
        self.accSamplingRate = accRate;
        [self.motionManager setAccelerometerUpdateInterval:1.0/accRate];
    }
    if (self.motionManager.isGyroAvailable == YES) {
        self.gyroSamplingRate = gyroRate;
        [self.motionManager setGyroUpdateInterval:1.0/gyroRate ];
        
    }
    if (self.motionManager.isMagnetometerAvailable == YES) {
        self.magSamplingRate = magRate;
        [self.motionManager setMagnetometerUpdateInterval:1.0/magRate];
    }
    
    self.deviceMotionSamplingRate = attRate;
    [self.motionManager setDeviceMotionUpdateInterval:1.0/attRate ];
}

-(float) avgAccSamplingRate {
    return [self.accTimestampArray count]/([[self.accTimestampArray lastObject] doubleValue] - [[self.accTimestampArray firstObject] doubleValue]);
}

-(float) avgGyroSamplingRate {
    return [self.gyroTimestampArray count]/([[self.gyroTimestampArray lastObject] doubleValue] - [[self.gyroTimestampArray firstObject] doubleValue]);
}

-(float) avgMagSamplingRate {
    return [self.magTimestampArray count]/([[self.magTimestampArray lastObject] doubleValue] - [[self.magTimestampArray firstObject] doubleValue]);
}

-(float) avgAttSamplingRate {
    return [self.attTimestampArray count]/([[self.attTimestampArray lastObject] doubleValue] - [[self.attTimestampArray firstObject] doubleValue]);
}

-(void) startLogging {
    
    [self.sensorLoggerArray removeAllObjects];
    [self.accTimestampArray removeAllObjects];
    [self.gyroTimestampArray removeAllObjects];
    [self.magTimestampArray removeAllObjects];
    [self.attTimestampArray removeAllObjects];
    
    self.logSwitch = YES;
    NSLog(@"sensor data start logging...");
}

-(void) stopLogging {
    self.logSwitch = NO;
    NSLog(@"sensor data stop logging.");
}

-(void) startSensor {
    NSLog(@"stop sensor");
    [self stopLogging];
    NSLog(@"start sensor logging");
    
    if (self.rawAccEnable) {
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            if (self.logSwitch == YES) {
                [self.sensorLoggerArray addObject:accelerometerData];
                [self.accTimestampArray addObject:[NSNumber numberWithDouble:accelerometerData.timestamp]];
            }
            
        }];
    }
    
    if (self.rawGyroEnable) {
        [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
            if (self.logSwitch== YES) {
                [self.sensorLoggerArray addObject:gyroData];
                [self.gyroTimestampArray addObject:[NSNumber numberWithDouble:gyroData.timestamp]];
            }
            
        }];
    }
    
    
    if (self.rawMagEnable) {
        [self.motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMagnetometerData *magnetometerData, NSError *error) {
            if (self.logSwitch == YES) {
                [self.sensorLoggerArray addObject:magnetometerData];
                [self.magTimestampArray addObject:[NSNumber numberWithDouble:magnetometerData.timestamp]];
            }
            
        }];
    }
    
    if (self.deviceMotionEnable) {
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            if (self.logSwitch == YES) {
                [self.sensorLoggerArray addObject:motion];
                [self.attTimestampArray addObject:[NSNumber numberWithDouble:motion.timestamp]];
            }
            
        }];
    }
    
}

-(void) stopSensor {
    if ([self.motionManager isAccelerometerActive]) {
        [self.motionManager stopAccelerometerUpdates];
    }
    if ([self.motionManager isGyroActive]) {
        [self.motionManager stopGyroUpdates];
    }
    if ([self.motionManager isMagnetometerActive]) {
        [self.motionManager stopMagnetometerUpdates];
    }
    if ([self.motionManager isDeviceMotionActive]) {
        [self.motionManager stopDeviceMotionUpdates];
    }
    
    NSLog(@"Sensor Logging Stopped");
}

-(void) writeToFile:(NSString *)prefix {
    NSError *error;
    NSDateFormatter * sdf = [[NSDateFormatter alloc] init];
    [sdf setDateFormat:@"yyMMdd_HHmm"];
    NSString *fileName = [[prefix stringByAppendingString:[sdf stringFromDate:[NSDate date]]] stringByAppendingPathExtension:@"txt"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    
    
    // if the file exists, delete it.
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] == YES)
    {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
    
    
    NSMutableString *text = [[NSMutableString alloc] init];
    
    NSString * formatString = @"%@ %f %f %f %f %f\n";
    for (CMLogItem *item in self.sensorLoggerArray) {
        
        if ([item isKindOfClass:[CMAccelerometerData class]]) {
            CMAccelerometerData * data = (CMAccelerometerData *) item;
            [text appendFormat:formatString,@"rawacc",data.acceleration.x,data.acceleration.y,data.acceleration.z, 0.0, data.timestamp];
        }
        
        if ([item isKindOfClass:[CMGyroData class]]) {
            CMGyroData * data = (CMGyroData *) item;
            [text appendFormat:formatString,@"rawgyro",data.rotationRate.x,data.rotationRate.y,data.rotationRate.z,0.0, data.timestamp];
        }
        
        if ([item isKindOfClass:[CMMagnetometerData class]]) {
            CMMagnetometerData * data = (CMMagnetometerData *) item;
            [text appendFormat:formatString,@"rawmag",data.magneticField.x,data.magneticField.y,data.magneticField.z,0.0,data.timestamp];
        }
        
        if ([item isKindOfClass:[CMDeviceMotion class]]) {
            CMDeviceMotion * data = (CMDeviceMotion *) item;
            [text appendFormat:formatString,@"acc",data.userAcceleration.x, data.userAcceleration.y,data.userAcceleration.z,0.0,data.timestamp];
            [text appendFormat:formatString,@"earthgravity",data.gravity.x, data.gravity.y,data.gravity.z,0.0,data.timestamp];
            [text appendFormat:formatString,@"gyro",data.rotationRate.x, data.rotationRate.y,data.rotationRate.z,0.0,data.timestamp];
            [text appendFormat:formatString,@"mag",data.magneticField.field.x, data.magneticField.field.y,data.magneticField.field.z,0.0,data.timestamp];
            [text appendFormat:formatString,@"quat",data.attitude.quaternion.w, data.attitude.quaternion.x,data.attitude.quaternion.y,data.attitude.quaternion.z,data.timestamp];
        }
    }
    
    
    
    [text writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    NSLog(@"%lu sensor logs written to file:\n%@",(unsigned long)[self.sensorLoggerArray count],fileName);
}

@end
