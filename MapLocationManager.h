//
//  MapLocationManager.h
//  OAConnect
//
//  Created by 李仁兵 on 15/11/23.
//  Copyright © 2015年 zengxiangrong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef double LocationFrequency; //定位频率

typedef NS_ENUM(NSUInteger, MapEngineType) {
    EngineTypeDefault = 0, //苹果自带地图,默认是苹果自带
    EngineTypeMAMap = 1    //高德地图
};

typedef  NS_ENUM(NSUInteger, LocationType) {
    LocationTypeOnce = 0,  //一次定位 默认是一次定位
    LocationTypeContinu = 1 //连续定位
};

//地址信息关键字
extern const NSString * kAddressFormattedAddress; //格式化地址
extern const NSString * kAddressCountry; //国家
extern const NSString * kAddressProvince; //省/直辖市
extern const NSString * kAddressCity; //市
extern const NSString * kAddressDistrict; //区
extern const NSString * kAddressTownship; //乡镇
extern const NSString * kAddressNeighborhood; //社区
extern const NSString * kAddressBuilding; //建筑
extern const NSString * kAddressCitycode; //城市编码
extern const NSString * kAddressAdcode; //区域编码

//位置信息关键字
extern const NSString * kLocationAltitude; // 海拔高度
extern const NSString * kLocationCourse; //行驶方向
extern const NSString * kLocationHorizontalAccuracy; //水平方向的精确度
extern const NSString * kLocationVerticalAccuracy;//垂直方向的精确度
extern const NSString * kLocationSpeed; //行驶速度
extern const NSString * kLocationTimestamp; //时间戳


@protocol MapLocationManagerGeocodeDelegate;
@protocol MapLocationManagerDelegate <NSObject>
/*!
 @method - (void)noCLAuthorization;
 @abstract 没有获取定位授权
 */
- (void)noCLAuthorization;

/*!
 @method - (void)startLocationManager;
 @abstract 开始定位
 */
- (void)startLocationManager;

/*!
 @method - (void)stopLocationManager;
 @abstract 停止定位
 */
- (void)stopLocationManager;

/*!
 @method - (void)succeedLocation:(CLLocationCoordinate2D)coordinate2D;
 @abstract 成功获得经纬度
 @param coordinate2D:CLLocationCoordinate2D 经纬度结构体参数
 */
- (void)succeedLocation:(CLLocationCoordinate2D)coordinate2D locationInfo:(NSDictionary *)locationInfoDict;

/*!
 @method - (void)failedLocation;
 @abstract 获取经纬度失败
 */
- (void)failedLocation;
@end

@interface MapLocationManager : NSObject
@property (nonatomic,weak) id<MapLocationManagerDelegate>delegate;
@property (nonatomic,weak) id<MapLocationManagerGeocodeDelegate>geocodeDelegate;

/*!
 定位精确度
 kCLLocationAccuracyBest; //最佳
 kCLLocationAccuracyNearestTenMeters;
 kCLLocationAccuracyHundredMeters;
 kCLLocationAccuracyKilometer;
 kCLLocationAccuracyThreeKilometers
 */
@property (nonatomic,assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic,assign) LocationType locationType; //定位类型
@property (nonatomic,assign) LocationFrequency frequency;//定位频率，单位m，多少米定位一次

/*!
 @method - (instancetype)initWithMapEngineType:(MapEngineType)mapEngineType;
 @abstract 初始化实例对象
 @param mapEngineType:MapEngineType 选择的引擎
 @return instancetype 返回实例对象
 */
- (instancetype)initWithMapEngineType:(MapEngineType)mapEngineType;

/*!
 @method - (void)startLocation;
 @abstract 开始定位
 */
- (void)startLocation;

/*!
 @method - (void)stopLocation;
 @abstract 结束定位
 */
- (void)stopLocation;

@end


@protocol MapLocationManagerGeocodeDelegate <NSObject>
/*!
 @method - (void)filterUsefulInfoWithAddressComponent:(NSDictionary *)addressComponentDict;
 @abstract 根据全部信息来获取想要的位置信息
 @param addressComponentDict:NSDictionary 位置地址信息元素
 */
- (void)filterUsefulInfoWithAddressComponent:(NSDictionary *)addressComponentDict andCoordinate2D:(CLLocationCoordinate2D)coordinate2D;

/*!
 @method - (void)failedGeocode;
 @abstract 经纬度逆地理编码失败
 */
- (void)failedGeocode;
@end

@interface MapLocationManager (Geocode)
/*!
 @method - (void)geocodeLocationWith:(CLLocationCoordinate2D)coordinate2D;
 @abstract 根据经纬度逆地理编码
 @param coordinate2D:CLLocationCoordinate2D 经纬度
 */
- (void)geocodeLocationWith:(CLLocationCoordinate2D)coordinate2D;
@end
