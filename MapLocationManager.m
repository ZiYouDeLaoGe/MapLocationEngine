//
//  MapLocationManager.m
//  OAConnect
//
//  Created by 李仁兵 on 15/11/23.
//  Copyright © 2015年 zengxiangrong. All rights reserved.
//

#import "MapLocationManager.h"
#import "CorrectLocation.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>
#import <AMapSearchKit/AMapSearchServices.h>


const NSString * kAddressFormattedAddress = @"kLocationFormattedAddress";
const NSString * kAddressCountry = @"kLocationCountry";
const NSString * kAddressProvince = @"kLocationProvince";
const NSString * kAddressCity = @"kLocationCity";
const NSString * kAddressDistrict = @"kLocationDistrict";
const NSString * kAddressTownship = @"kLocationTownship";
const NSString * kAddressNeighborhood = @"kLocationNeighborhood";
const NSString * kAddressBuilding = @"kLocationBuilding";
const NSString * kAddressCitycode = @"kLocationCitycode";
const NSString * kAddressAdcode = @"kLocationAdcode";

const NSString * kLocationAltitude = @"kLocationAltitude";
const NSString * kLocationCourse = @"kLocationCourse";
const NSString * kLocationHorizontalAccuracy = @"kLocationHorizontalAccuracy";
const NSString * kLocationVerticalAccuracy = @"kLocationVerticalAccuracy";
const NSString * kLocationSpeed = @"kLocationSpeed";
const NSString * kLocationTimestamp = @"kLocationTimestamp";

@interface MapLocationManager ()
<
CLLocationManagerDelegate,
AMapSearchDelegate
>
{
    CLLocationManager * _locationManager;
    AMapSearchAPI * _AMSearchAPI;
    BOOL _isOnceLocating;//一次定位是否正在定位中
}
@property (nonatomic,assign) MapEngineType mapEngineType;//引擎类型
@end

@implementation MapLocationManager
- (instancetype)initWithMapEngineType:(MapEngineType)mapEngineType{
    self.mapEngineType = mapEngineType;
    return [self init];
}

- (instancetype)init
{
    if (self = [super init]) {
        if (self.mapEngineType != EngineTypeMAMap) {
            self.mapEngineType = EngineTypeDefault;
        }
        _locationType = LocationTypeOnce;
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _isOnceLocating = NO;
    }
    return self;
}

- (void)dealloc
{
    _locationManager.delegate = nil;
    [self stopLocation];
}

- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy
{
    _desiredAccuracy = desiredAccuracy;
    _locationManager.desiredAccuracy = _desiredAccuracy;
}

- (void)setFrequency:(LocationFrequency)frequency
{
    _frequency = frequency;
    _locationManager.distanceFilter = _frequency;
}

- (void)setLocationType:(LocationType)locationType
{
    _locationType = locationType;
}

- (void)startLocation
{
    //是否启用定位服务，通常如果用户没有启用定位服务可以提示用户打开定位服务
    if([CLLocationManager locationServicesEnabled]) {
        //用户尚未决定是否启用定位
        if(CLLocationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined){
            
            if (_locationManager && [_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [_locationManager requestWhenInUseAuthorization];//调用了这句,就会弹出允许框了.
            }
        }
        //用户已经明确禁止应用使用定位服务或者当前系统定位服务处于关闭状态
        if(CLLocationManager.authorizationStatus == kCLAuthorizationStatusDenied){
            if (_delegate && [_delegate respondsToSelector:@selector(noCLAuthorization)]) {
                [_delegate noCLAuthorization];
            }
            return;
        }
        if (_locationType == LocationTypeOnce) {
            _isOnceLocating = YES;
        }
        [_locationManager startUpdatingLocation];
        if (_delegate && [_delegate respondsToSelector:@selector(startLocationManager)]) {
            [_delegate startLocationManager];
        }
    }else{
        if (_delegate && [_delegate respondsToSelector:@selector(noCLAuthorization)]) {
            [_delegate noCLAuthorization];
        }
    }
}

- (void)stopLocation
{
    [_locationManager stopUpdatingHeading];
    if (_locationType == LocationTypeOnce) {
        _isOnceLocating = NO;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(stopLocationManager)]) {
        [_delegate stopLocationManager];
    }
}

#pragma mark - CLLocationManagerDelegate_EngineTypeDefault

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    //将火星坐标转化为地理坐标
    CLLocation * correctLocation = [CorrectLocation transformToMars:newLocation];
    if (_delegate && [_delegate respondsToSelector:@selector(succeedLocation:locationInfo:)]) {
        NSMutableDictionary * locationInfoDict = [[NSMutableDictionary alloc] initWithCapacity:0];
        
        [locationInfoDict setObject:[NSString stringWithFormat:@"%lf",newLocation.altitude] forKey:kLocationAltitude];
        [locationInfoDict setObject:[NSString stringWithFormat:@"%lf",newLocation.course] forKey:kLocationCourse];
        [locationInfoDict setObject:[NSString stringWithFormat:@"%lf",newLocation.horizontalAccuracy] forKey:kLocationHorizontalAccuracy];
        [locationInfoDict setObject:[NSString stringWithFormat:@"%lf",newLocation.verticalAccuracy] forKey:kLocationVerticalAccuracy];
        [locationInfoDict setObject:[NSString stringWithFormat:@"%lf",newLocation.speed] forKey:kLocationSpeed];
        [locationInfoDict setObject:newLocation.timestamp forKey:kLocationTimestamp];
        
        if (_locationType == LocationTypeOnce) {
            if (_isOnceLocating) {
                [_delegate succeedLocation:correctLocation.coordinate locationInfo:locationInfoDict];
            }
        }
        if (_locationType == LocationTypeContinu) {
            [_delegate succeedLocation:correctLocation.coordinate locationInfo:locationInfoDict];
        }
    }
    switch (_locationType) {
        case LocationTypeOnce:
            [self stopLocation];
            break;
        case LocationTypeContinu:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (_delegate && [_delegate respondsToSelector:@selector(failedLocation)]) {
        [_delegate failedLocation];
    }
}
@end

#pragma mark - MapLocationManager(Geocode)

@implementation MapLocationManager(Geocode)
- (void)geocodeLocationWith:(CLLocationCoordinate2D)coordinate2D
{
    switch (_mapEngineType) {
        case EngineTypeDefault:
            [self geocodeDefaultEngineLocationWith:coordinate2D];
            break;
        case EngineTypeMAMap:
            [self geocodeMAEngineLocationWith:coordinate2D];
            break;
    }
}

#pragma mark - 系统定位逆地理编码逻辑

- (void)geocodeDefaultEngineLocationWith:(CLLocationCoordinate2D)coordinate2D
{
    CLGeocoder * reverseGeocoder = [[CLGeocoder alloc] init];
    CLLocation * location = [[CLLocation alloc] initWithLatitude:coordinate2D.latitude longitude:coordinate2D.longitude];
    [reverseGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error){
        CLPlacemark * placeMark = [placemarks objectAtIndex:0];
        if (!error) {
            NSMutableDictionary * addressComponentDict = [[NSMutableDictionary alloc] initWithCapacity:0];
            if ([placeMark.addressDictionary objectForKey:@"FormattedAddressLines"]) {
                [addressComponentDict setObject:[[placeMark.addressDictionary objectForKey:@"FormattedAddressLines"] firstObject] forKey:kAddressFormattedAddress];
            }
            if ([placeMark.addressDictionary objectForKey:@"Country"]) {
                [addressComponentDict setObject:[placeMark.addressDictionary objectForKey:@"Country"] forKey:kAddressCountry];
            }
            if ([placeMark.addressDictionary objectForKey:@"State"]) {
                [addressComponentDict setObject:[placeMark.addressDictionary objectForKey:@"State"] forKey:kAddressProvince];
            }
            if ([placeMark.addressDictionary objectForKey:@"City"]) {
                [addressComponentDict setObject:[placeMark.addressDictionary objectForKey:@"City"] forKey:kAddressCity];
            }
            if ([placeMark.addressDictionary objectForKey:@"SubLocality"]) {
                [addressComponentDict setObject:[placeMark.addressDictionary objectForKey:@"SubLocality"] forKey:kAddressDistrict];
            }
            if ([placeMark.addressDictionary objectForKey:@"Street"]) {
                [addressComponentDict setObject:[placeMark.addressDictionary objectForKey:@"Street"] forKey:kAddressTownship];
            }
            if ([placeMark.addressDictionary objectForKey:@"Thoroughfare"]) {
                [addressComponentDict setObject:[placeMark.addressDictionary objectForKey:@"Thoroughfare"] forKey:kAddressNeighborhood];
            }
            if ([placeMark.addressDictionary objectForKey:@"SubThoroughfare"]) {
                [addressComponentDict setObject:[placeMark.addressDictionary objectForKey:@"SubThoroughfare"] forKey:kAddressBuilding];
            }
            if (_geocodeDelegate&&[_geocodeDelegate respondsToSelector:@selector(filterUsefulInfoWithAddressComponent:andCoordinate2D:)]) {
                [_geocodeDelegate filterUsefulInfoWithAddressComponent:addressComponentDict andCoordinate2D:coordinate2D];
            }
        }else{
            //逆地理编码失败
            if (_geocodeDelegate&&[_geocodeDelegate respondsToSelector:@selector(failedGeocode)]) {
                [_geocodeDelegate failedGeocode];
                [_geocodeDelegate failedGeocode];
            }
        }
    }];
}

#pragma mark - 高德地图逆地理编码逻辑

- (void)geocodeMAEngineLocationWith:(CLLocationCoordinate2D)coordinate2D
{
    _AMSearchAPI = [[AMapSearchAPI alloc] init];
    _AMSearchAPI.delegate = self;
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = [AMapGeoPoint locationWithLatitude:coordinate2D.latitude longitude:coordinate2D.longitude];
    regeo.requireExtension = YES;
    [_AMSearchAPI AMapReGoecodeSearch:regeo];
}

//逆地理编码
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    CLLocationCoordinate2D coordinate2D = CLLocationCoordinate2DMake(request.location.latitude, request.location.longitude);
    if (response.regeocode != nil)
    {
        NSMutableDictionary * addressComponentDict = [[NSMutableDictionary alloc] initWithCapacity:0];
        if (response.regeocode.formattedAddress) {
            [addressComponentDict setObject:response.regeocode.formattedAddress forKey:kAddressFormattedAddress];
        }
        if (response.regeocode.addressComponent.province) {
            [addressComponentDict setObject:response.regeocode.addressComponent.province forKey:kAddressProvince];
        }
        if (response.regeocode.addressComponent.city) {
            [addressComponentDict setObject:response.regeocode.addressComponent.city forKey:kAddressCity];
        }
        if (response.regeocode.addressComponent.district) {
            [addressComponentDict setObject:response.regeocode.addressComponent.district forKey:kAddressDistrict];
        }
        if (response.regeocode.addressComponent.township) {
            [addressComponentDict setObject:response.regeocode.addressComponent.township forKey:kAddressTownship];
        }
        if (response.regeocode.addressComponent.neighborhood) {
            [addressComponentDict setObject:response.regeocode.addressComponent.neighborhood forKey:kAddressNeighborhood];
        }
        if (response.regeocode.addressComponent.building) {
            [addressComponentDict setObject:response.regeocode.addressComponent.building forKey:kAddressBuilding];
        }
        if (response.regeocode.addressComponent.citycode) {
            [addressComponentDict setObject:response.regeocode.addressComponent.citycode forKey:kAddressCitycode];
        }
        if (response.regeocode.addressComponent.adcode) {
            [addressComponentDict setObject:response.regeocode.addressComponent.adcode forKey:kAddressAdcode];
        }
        if (_geocodeDelegate&&[_geocodeDelegate respondsToSelector:@selector(filterUsefulInfoWithAddressComponent:andCoordinate2D:)]) {
            [_geocodeDelegate filterUsefulInfoWithAddressComponent:addressComponentDict andCoordinate2D:coordinate2D];
        }
    }else{
        //逆地理编码失败
        if (_geocodeDelegate&&[_geocodeDelegate respondsToSelector:@selector(failedGeocode)]) {
            [_geocodeDelegate failedGeocode];
            [_geocodeDelegate failedGeocode];
        }
    }
}
@end
