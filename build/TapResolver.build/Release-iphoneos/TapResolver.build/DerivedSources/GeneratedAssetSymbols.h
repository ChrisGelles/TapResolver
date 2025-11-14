#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "MuseumMap-8k" asset catalog image resource.
static NSString * const ACImageNameMuseumMap8K AC_SWIFT_PRIVATE = @"MuseumMap-8k";

/// The "MuseumMap-thumbnail" asset catalog image resource.
static NSString * const ACImageNameMuseumMapThumbnail AC_SWIFT_PRIVATE = @"MuseumMap-thumbnail";

/// The "facing-glyph" asset catalog image resource.
static NSString * const ACImageNameFacingGlyph AC_SWIFT_PRIVATE = @"facing-glyph";

/// The "myFirstFloor_v03-metric" asset catalog image resource.
static NSString * const ACImageNameMyFirstFloorV03Metric AC_SWIFT_PRIVATE = @"myFirstFloor_v03-metric";

/// The "myFirstFloor_v03-metric-thumb" asset catalog image resource.
static NSString * const ACImageNameMyFirstFloorV03MetricThumb AC_SWIFT_PRIVATE = @"myFirstFloor_v03-metric-thumb";

#undef AC_SWIFT_PRIVATE
