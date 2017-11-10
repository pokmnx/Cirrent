// Generated by Apple Swift version 3.1 (swiftlang-802.0.53 clang-802.0.42)
#pragma clang diagnostic push

#if defined(__has_include) && __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if defined(__has_include) && __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...)
# endif
#endif

#if defined(__has_attribute) && __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(objc_method_family)
# define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
#else
# define SWIFT_METHOD_FAMILY(X)
#endif
#if defined(__has_attribute) && __has_attribute(noescape)
# define SWIFT_NOESCAPE __attribute__((noescape))
#else
# define SWIFT_NOESCAPE
#endif
#if defined(__has_attribute) && __has_attribute(warn_unused_result)
# define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define SWIFT_WARN_UNUSED_RESULT
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if defined(__has_attribute) && __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_EXTRA _name : _type
# if defined(__has_feature) && __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME) SWIFT_ENUM(_type, _name)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if defined(__has_feature) && __has_feature(modules)
@import ObjectiveC;
@import Foundation;
@import UIKit;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
typedef SWIFT_ENUM(NSInteger, CREDENTIAL_RESPONSE_) {
  CREDENTIAL_RESPONSE_SUCCESS = 0,
  CREDENTIAL_RESPONSE_FAILED_NO_RESPONSE = 1,
  CREDENTIAL_RESPONSE_FAILED_INVALID_STATUS = 2,
  CREDENTIAL_RESPONSE_FAILED_INVALID_TOKEN = 3,
  CREDENTIAL_RESPONSE_NOT_SoftAP = 4,
};

@class Model;
enum TOKEN_TYPE_ : NSInteger;
enum FIND_DEVICE_RESULT_ : NSInteger;
@class Device;
enum RESPONSE_ : NSInteger;
@class Network;
@class KnownNetwork;
@class DeviceStatus;
enum JOINING_STATUS_ : NSInteger;
enum SoftAP_RESPONSE_ : NSInteger;

/// The CirrentService is the main entry point to the Cirrent SDK.
SWIFT_CLASS("_TtC10CirrentSDK14CirrentService")
@interface CirrentService : NSObject
SWIFT_CLASS_PROPERTY(@property (nonatomic, class, strong) CirrentService * _Nonnull sharedService;)
+ (CirrentService * _Nonnull)sharedService SWIFT_WARN_UNUSED_RESULT;
+ (void)setSharedService:(CirrentService * _Nonnull)value;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
/// The model contains the variables that are shared between the mobile app and the Cirrent SDK.
@property (nonatomic, strong) Model * _Nullable model;
/// Whether softAP is supported by the device. This tells the Cirrent SDK whether it should try to
/// onboard the device via SoftAP if it is unable to onboard the device via the Cirrent cloud.
/// \param bSupport if true, device supports SoftAP.  If false, device does not support SoftAP.
///
- (void)supportSoftAPWithBSupport:(BOOL)bSupport;
/// Stores the OwnerID associated with this application instance. This is used by the Cirrent cloud
/// when it is matching up the location of the mobile app to the location of the device (to find nearby devices).
/// The sample app uses the user’s login as the ownerID.
/// \param identifier unique id for the owner of this app. If empty, the Cirrent SDK will generate a unique id.
///
///
/// returns:
/// OwnerID
- (void)setOwnerIdentifierWithIdentifier:(NSString * _Nonnull)identifier;
/// This function is the first method to be called during the on-boarding process. It will find nearby discoverable
/// devices in the Cirrent cloud.  It will first upload the location of the phone, and then look for devices of the
/// correct type, that are nearby to this mobile app (based on matching location
/// and/or WI-FI scans), and that have not been claimed by another user.  It will return a list of nearby devices.
/// \param tokenHandler method that will generate a SEARCH token
///
/// \param completion callback (FIND_DEVICE_RESULT, [Device]?) -> Void
///
- (void)findDeviceWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod completion:(void (^ _Nonnull)(enum FIND_DEVICE_RESULT_, NSArray<Device *> * _Nullable))completion;
/// This is an optional method that requests that the device perform some identifying action, such as flashing a light
/// or playing a sound.  The request is sent to the Cirrent cloud, and the device will perform the action when it checks
/// in with the cloud to see if there are any actions to be performed. This helps the user to confirm that they
/// onboarding the correct device.
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID Cirrent Device Identifier
///
/// \param completion callback (RESPONSE) -> Void
///
- (void)identifyYourselfWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID completion:(void (^ _Nonnull)(enum RESPONSE_))completion;
/// Some products require that the user take some action on the device to show they have selected the correct device.
/// If this product requires user action, this method is called to poll to see if the user has taken the action on the
/// device.  It polls the cloud repeatedly until device reports that the user has performed some action on the device
/// (e.g. pressed a button on the device)
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param completion a string describing the action that was performed
///
- (void)pollForUserActionWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod completion:(void (^ _Nonnull)(Device * _Nonnull))completion;
/// Stop polling for user action - this is called if the app decides to wait no longer for the user to
/// complete the action on the device.  This tells the SDK to cancel the timer controlling how long to
/// poll for the user action.  This might be necessary if the user selects a different device, for example.
- (void)stopPollForUserAction;
/// Delete a network that was previously provisioned for this device
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID the device from which the network should be deleted
///
/// \param network the network to be deleted
///
/// \param completion completion handler
///
- (void)deleteNetworkWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID network:(Network * _Nonnull)network completion:(void (^ _Nonnull)(enum RESPONSE_))completion;
/// Add a new network to an already-claimed device
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID the device to which the network should be added
///
/// \param network the network to be deleted
///
/// \param password the pre-shared key for the network being added
///
/// \param completion completion handler
///
- (void)addNetworkWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID network:(Network * _Nonnull)network password:(NSString * _Nonnull)password completion:(void (^ _Nonnull)(enum RESPONSE_))completion;
/// This method is called after the user has selected the device.  It takes as input the device id for the selected
/// device, and queries the Cirrent cloud for the most recent device status. The device status will include the Wi-Fi
/// scan list from the device, which can be used to show the user a drop-down list of the networks the device can see.
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID the device whose network scan list we need
///
/// \param completion completion handler
///
- (void)getCandidateNetworksWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID completion:(void (^ _Nonnull)(NSArray<KnownNetwork *> * _Nullable))completion;
/// Get the list of networks already provisioned in this device
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID the device identifier
///
/// \param completion completion handler
///
- (void)getKnownNetworksWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID completion:(void (^ _Nonnull)(NSArray<KnownNetwork *> * _Nullable))completion;
/// Get Device Status from Cirrent Cloud
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param device the device object which user should know the status
///
/// \param completion completion handler
///
- (void)getDeviceStatusWithTokenMethod:(void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID uptime:(BOOL)uptime completion:(void (^ _Nonnull)(enum RESPONSE_, DeviceStatus * _Nullable))completion;
/// If the app is on a private network for which the broadband provider has credentials, you can let the user choose to
/// have the provider deliver the credentials to the Cirrent cloud, instead of having the user enter the private network
/// credentials manually. The putProviderCredentials method instructs Cirrent to get the private network credentials
/// from the broadband provider, so that they can be retrieved by the device.
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID id of device that the credentials are for
///
/// \param providerUDID UDID of a provider who has the credentials
///
/// \param completion completion handler
///
- (void)putProviderCredentialsWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID providerUDID:(NSString * _Nonnull)providerUDID completion:(void (^ _Nonnull)(enum CREDENTIAL_RESPONSE_, NSArray<NSString *> * _Nullable))completion;
- (BOOL)selectDeviceWithDeviceID:(NSString * _Nonnull)deviceID SWIFT_WARN_UNUSED_RESULT;
/// This method binds the device, so it is considered ‘claimed’ by this user, and will no longer be discoverable by
/// other users looking for nearby devices.  Cirrent keeps track of whether a device is discoverable or not, but does
/// not keep track of which user has bound the device. That is managed in the product cloud.
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID ID of the device that will be bound (no longer discoverable)
///
/// \param completion completion handler
///
- (void)bindDeviceWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID friendlyName:(NSString * _Nullable)friendlyName completion:(void (^ _Nonnull)(enum RESPONSE_))completion;
/// This method resets the device state in the Cirrent cloud, so it is no longer considered ‘claimed’ by this user, and
/// will be discoverable by other users looking for nearby devices.  The Cirrent cloud will also discard any status it
/// has for this device (known networks, wi-fi scans etc.).
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID id of the device being unbound
///
/// \param completion completion handler
///
- (void)resetDeviceWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID completion:(void (^ _Nonnull)(enum RESPONSE_))completion;
/// Send private network credentials to the device (via the Cirrent cloud or over SoftAP). The network credentials
/// are retrieved from the selectedNetwork in the model.
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID id of device to receive the credentials
///
/// \param addToVault whether the credential should be stored in the credential vault to be used by future devices of the same type
///
/// \param completion completion handler
///
- (void)putPrivateCredentialsWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID bAddToVault:(BOOL)bAddToVault completion:(void (^ _Nonnull)(enum CREDENTIAL_RESPONSE_, NSArray<NSString *> * _Nullable))completion;
/// The getDeviceJoiningStatus method is used to get status updates from the device, via the Cirrent cloud, or
/// over SoftAP, while the device is moving from the ZipKey network to the private network.<br/>
/// The getDeviceJoiningStatus method may call the
/// callback handler more than once, to give updated statuses as the device goes through the onboarding process.
/// \param tokenMethod method that will generate a token authorizing this function
///
/// \param deviceID id of device whose status we are checking
///
/// \param handler joining handler
///
- (void)getDeviceJoiningStatusWithTokenMethod:(SWIFT_NOESCAPE void (^ _Nonnull)(enum TOKEN_TYPE_, NSString * _Nullable, void (^ _Nonnull)(NSString * _Nullable)))tokenMethod deviceID:(NSString * _Nonnull)deviceID handler:(void (^ _Nonnull)(enum JOINING_STATUS_))handler;
/// Cancel any timers that are currently running in the Cirrent SDK
- (void)stopAllAction;
/// Wait to confirm that the app has joined the SoftAP network so that onboarding can now proceed over
/// the SoftAP network.This method waits for the phone to join the softAP network. It then queries the device
/// over the SoftAP network for its status.  Once the status has been received, the mobile app can call
/// putPrivateCredentials, and then getDeviceJoiningStatus, just as if it were communicating via the Cirrent cloud.
/// \param handler completion handler
///
- (void)processSoftAPWithHandler:(void (^ _Nonnull)(enum SoftAP_RESPONSE_))handler;
/// check if the phone is on cellular network or not
///
/// returns:
/// return true if on cellular network, false otherwise
- (BOOL)isOnCellularNetwork SWIFT_WARN_UNUSED_RESULT;
/// return SSID of the network the phone is currently on
///
/// returns:
/// return SSID of current network
- (NSString * _Nullable)getCurrentSSIDWithBLog:(BOOL)bLog SWIFT_WARN_UNUSED_RESULT;
@end


/// The device that the app is onboarding
SWIFT_CLASS("_TtC10CirrentSDK6Device")
@interface Device : NSObject
/// The name the user has assigned to this device
@property (nonatomic, copy) NSString * _Nonnull friendlyName;
/// A picture of the device
///
/// returns:
/// URL to image
- (NSString * _Nonnull)getImageURL SWIFT_WARN_UNUSED_RESULT;
/// Unique ID for this device
///
/// returns:
/// the unique device id
- (NSString * _Nonnull)getDeviceID SWIFT_WARN_UNUSED_RESULT;
/// If a provider helped to onboard this device (by letting it join the provider’s ZipKey network
/// this field will be populated with the name of the provider whose ZipKey network was used
///
/// returns:
/// name of provider
- (NSString * _Nonnull)getProviderAttribution SWIFT_WARN_UNUSED_RESULT;
/// If a provider helped to onboard this device (by letting it join the provider’s ZipKey network
/// this field will be populated with a URL pointing to the logo of the provider whose ZipKey network was used
///
/// returns:
/// URL to logo
- (NSString * _Nonnull)getProviderAttributionLogo SWIFT_WARN_UNUSED_RESULT;
/// If a provider helped to onboard this device (by letting it join the provider’s ZipKey network
/// this field will be populated with a URL pointing a site where the user can learn more about this provider
///
/// returns:
/// URL to learn-more website
- (NSString * _Nonnull)getProviderAttributionLearnMoreURL SWIFT_WARN_UNUSED_RESULT;
/// Indicates whether this device can support the identify-action. If true, the user can be given the option to
/// have the device perform an identify-action (e.g play a sound or flash a light)
///
/// returns:
/// true if identify-action is enabled for this device, false otherwise
- (BOOL)getIdentifyingActionEnabled SWIFT_WARN_UNUSED_RESULT;
/// If this device can support the identify-action, returns a textual description of the identify action
/// so that the user knows what to look for (e.g. a sound will play).
///
/// returns:
/// string describing the identify action
- (NSString * _Nonnull)getIdentifyingActionDescription SWIFT_WARN_UNUSED_RESULT;
/// Indicates whether this device can support the user-action. If true, the user is required to take some
/// action on the device before they can proceed to onboarding the device.
///
/// returns:
/// true if user-action is enabled for this device, false otherwise
- (BOOL)getUserActionEnabled SWIFT_WARN_UNUSED_RESULT;
/// Returns true if the user confirmed ownership (by performing the user action)
///
/// returns:
/// true if ownership was confirmed, false otherwise
- (BOOL)getConfirmedOwnerShip SWIFT_WARN_UNUSED_RESULT;
/// If this device can support the user-action, returns a textual description of the user action
/// so that the user knows they are expected to do (e.g. push volume-up button on the device).
///
/// returns:
/// string describing the user action
- (NSString * _Nonnull)getUserActionDescription SWIFT_WARN_UNUSED_RESULT;
- (NSInteger)getDeviceType SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


SWIFT_CLASS("_TtC10CirrentSDK12DeviceStatus")
@interface DeviceStatus : NSObject
- (NSArray<KnownNetwork *> * _Nonnull)getKnownNetworks SWIFT_WARN_UNUSED_RESULT;
- (NSArray<Network *> * _Nonnull)getWifiScans SWIFT_WARN_UNUSED_RESULT;
- (BOOL)isBound SWIFT_WARN_UNUSED_RESULT;
- (NSDate * _Nullable)getTimeStamp SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

typedef SWIFT_ENUM(NSInteger, FIND_DEVICE_RESULT_) {
  FIND_DEVICE_RESULT_SUCCESS = 0,
  FIND_DEVICE_RESULT_FAILED_NETWORK_OFFLINE = 1,
  FIND_DEVICE_RESULT_FAILED_LOCATION_DISABLED = 2,
  FIND_DEVICE_RESULT_FAILED_UPLOAD_ENVIRONMENT = 3,
  FIND_DEVICE_RESULT_FAILED_NO_DEVICE = 4,
  FIND_DEVICE_RESULT_FAILED_NO_RESPONSE = 5,
  FIND_DEVICE_RESULT_FAILED_INVALID_STATUS = 6,
  FIND_DEVICE_RESULT_FAILED_INVALID_TOKEN = 7,
};

typedef SWIFT_ENUM(NSInteger, JOINING_STATUS_) {
  JOINING_STATUS_JOINED = 0,
  JOINING_STATUS_RECEIVED_CREDS = 1,
  JOINING_STATUS_ATTEMPTING_TO_JOIN = 2,
  JOINING_STATUS_OPTIMIZING_CONNECTION = 3,
  JOINING_STATUS_TIMED_OUT = 4,
  JOINING_STATUS_FAILED = 5,
  JOINING_STATUS_GET_DEVICE_STATUS_FAILED = 6,
  JOINING_STATUS_SELECTED_DEVICE_NIL = 7,
  JOINING_STATUS_FAILED_NO_RESPONSE = 8,
  JOINING_STATUS_FAILED_INVALID_STATUS = 9,
  JOINING_STATUS_FAILED_INVALID_TOKEN = 10,
  JOINING_STATUS_NOT_SoftAP_NETWORK = 11,
};


/// A network that is provisioned on the device
SWIFT_CLASS("_TtC10CirrentSDK12KnownNetwork")
@interface KnownNetwork : NSObject
/// The SSID of the network
@property (nonatomic, copy) NSString * _Nonnull ssid;
/// The priority of this network. The device will join the highest priority network that it can see.
@property (nonatomic) NSInteger priority;
- (NSString * _Nonnull)getStatus SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

typedef SWIFT_ENUM(NSInteger, LOG_EVENT_) {
  LOG_EVENT_SEARCH_START = 0,
  LOG_EVENT_TOKEN_RECEIVED = 1,
  LOG_EVENT_TOKEN_ERROR = 2,
  LOG_EVENT_LOCATION = 3,
  LOG_EVENT_LOCATION_ERROR = 4,
  LOG_EVENT_WIFI_SCAN = 5,
  LOG_EVENT_WIFI_SCAN_ERROR = 6,
  LOG_EVENT_DEVICES_RECEIVED = 7,
  LOG_EVENT_DEVICE_SELECTED = 8,
  LOG_EVENT_DEVICE_BOUND = 9,
  LOG_EVENT_PROVIDER_CREDS = 10,
  LOG_EVENT_USER_CREDS = 11,
  LOG_EVENT_STATUS = 12,
  LOG_EVENT_STATUS_ERROR = 13,
  LOG_EVENT_SoftAP = 14,
  LOG_EVENT_SoftAP_ERROR = 15,
  LOG_EVENT_SoftAP_SCREEN = 16,
  LOG_EVENT_SoftAP_JOINED = 17,
  LOG_EVENT_SoftAP_DROP = 18,
  LOG_EVENT_SoftAP_LONG_DURATION = 19,
  LOG_EVENT_CREDS_TIMEOUT = 20,
  LOG_EVENT_CLOUD_CONNECTION_ERROR = 21,
  LOG_EVENT_JOINED_FAILED = 22,
  LOG_EVENT_SUCCESS = 23,
  LOG_EVENT_EXIT = 24,
  LOG_EVENT_DEBUG = 25,
};

@class ProviderKnownNetwork;

/// Data structure for Cirrent SDK
SWIFT_CLASS("_TtC10CirrentSDK5Model")
@interface Model : NSObject
@property (nonatomic, strong) Device * _Nullable selectedDevice;
@property (nonatomic, strong) Network * _Nullable selectedNetwork;
@property (nonatomic, copy) NSString * _Nullable selectedNetworkPassword;
@property (nonatomic, copy) NSString * _Nullable credentialId;
@property (nonatomic, copy) NSString * _Nullable providerName;
@property (nonatomic, strong) ProviderKnownNetwork * _Nullable selectedProvider;
/// SoftAPSSID is the SSID the phone will use to associate to the device’s softAP network
@property (nonatomic, copy) NSString * _Nonnull SoftAPSSID;
/// Returns true if device is on a ZipKey network
///
/// returns:
/// true if on ZipKey network
- (BOOL)isOnZipKeyNetwork SWIFT_WARN_UNUSED_RESULT;
/// Gets the SSID of the network the phone is on
///
/// returns:
/// SSID
- (NSString * _Nullable)getSSID SWIFT_WARN_UNUSED_RESULT;
/// Gets the list of nearby devices
///
/// returns:
/// List of devices that are nearby, turned on recently and unclaimed
- (NSArray<Device *> * _Nullable)getDevices SWIFT_WARN_UNUSED_RESULT;
/// Gets the name of the provider provisioning this network
///
/// returns:
/// provider name
- (NSString * _Nullable)getProviderName SWIFT_WARN_UNUSED_RESULT;
/// Gets the name of the ZipKey hotspot that this device joined
///
/// returns:
/// name of ZipKey network
- (NSString * _Nullable)getZipKeyHotSpot SWIFT_WARN_UNUSED_RESULT;
/// Gets information about the provider that can provision this private network
///
/// returns:
/// ProviderKnownNetwork structure for this provider
- (ProviderKnownNetwork * _Nullable)getProviderNetwork SWIFT_WARN_UNUSED_RESULT;
- (void)setProviderNetworkWithNetwork:(ProviderKnownNetwork * _Nullable)network;
/// Returns the list of Wi-Fi networks that the device can see
///
/// returns:
/// List of networks
- (NSArray<Network *> * _Nonnull)getNetworks SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


@interface NSNumber (SWIFT_EXTENSION(CirrentSDK))
@end


/// A network in the wi-fi scan list
SWIFT_CLASS("_TtC10CirrentSDK7Network")
@interface Network : NSObject
/// The SSID for the network the device can see
@property (nonatomic, copy) NSString * _Nonnull ssid;
/// The network flags (e.g. security type)
@property (nonatomic, copy) NSString * _Nonnull flags;
/// Whether this is an open or secure network
@property (nonatomic) BOOL open;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end


/// ProviderKnownNetwork - if the user’s phone is on a private network for which the provider has the credentials
/// the user can be given an option to have the provider provision the network (instead of requiring the user to
/// manually enter the credentials).
SWIFT_CLASS("_TtC10CirrentSDK20ProviderKnownNetwork")
@interface ProviderKnownNetwork : NSObject
/// Get the name of the provider who can provision this network
///
/// returns:
/// the name of the provider
- (NSString * _Nonnull)getProviderName SWIFT_WARN_UNUSED_RESULT;
/// Get the SSID of the network that the provider can provision
///
/// returns:
/// SSID
- (NSString * _Nonnull)getSSID SWIFT_WARN_UNUSED_RESULT;
/// Get the logo to show for this provider (a URL to an image)
///
/// returns:
/// logo URL
- (NSString * _Nonnull)getProviderLogo SWIFT_WARN_UNUSED_RESULT;
/// Gets the unique id for this provider. This will be passed into the PutProviderCredentials call
///
/// returns:
/// UUID
- (NSString * _Nonnull)getProviderUUID SWIFT_WARN_UNUSED_RESULT;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

typedef SWIFT_ENUM(NSInteger, RESPONSE_) {
  RESPONSE_SUCCESS = 0,
  RESPONSE_FAILED_NO_RESPONSE = 1,
  RESPONSE_FAILED_INVALID_STATUS = 2,
  RESPONSE_FAILED_INVALID_TOKEN = 3,
  RESPONSE_FAILED_INVALID_DEVICE_ID = 4,
};

typedef SWIFT_ENUM(NSInteger, SoftAP_RESPONSE_) {
  SoftAP_RESPONSE_SUCCESS_WITH_SoftAP = 0,
  SoftAP_RESPONSE_FAILED_NOT_GET_SoftAP_IP = 1,
  SoftAP_RESPONSE_FAILED_NOT_SoftAP_SSID = 2,
  SoftAP_RESPONSE_FAILED_SoftAP_NO_RESPONSE = 3,
  SoftAP_RESPONSE_FAILED_SoftAP_INVALID_STATUS = 4,
  SoftAP_RESPONSE_FAILED_SoftAP_NOT_SUPPORTED = 5,
};

typedef SWIFT_ENUM(NSInteger, TOKEN_TYPE_) {
  TOKEN_TYPE_SEARCH = 0,
  TOKEN_TYPE_BIND = 1,
  TOKEN_TYPE_MANAGE = 2,
  TOKEN_TYPE_ANY = 3,
};


@interface UIDevice (SWIFT_EXTENSION(CirrentSDK))
@end

#pragma clang diagnostic pop