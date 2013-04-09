//
//  
//    ___  _____   ______  __ _   _________ 
//   / _ \/ __/ | / / __ \/ /| | / / __/ _ \
//  / , _/ _/ | |/ / /_/ / /_| |/ / _// , _/
// /_/|_/___/ |___/\____/____/___/___/_/|_| 
//
//  Created by Bart Claessens. bart (at) revolver . be
//

#import "REVClusterManager.h"
#import "REVClusterMapView.h"

@implementation REVClusterManager


+ (NSArray *)clusterAnnotationsForMapView:(MKMapView *)mapView forAnnotations:(NSArray *)pins blocks:(NSUInteger)blocks minClusterLevel:(NSUInteger)minClusterLevel {
    NSMutableArray *visibleAnnotations = [NSMutableArray array];
    
    double tileX = mapView.visibleMapRect.origin.x;
    double tileY = mapView.visibleMapRect.origin.y;
    float tileWidth = mapView.visibleMapRect.size.width/blocks;
    float tileHeight = mapView.visibleMapRect.size.height/blocks;
    
    MKMapRect mapRect = MKMapRectWorld;
    NSUInteger maxWidthBlocks = round(mapRect.size.width / tileWidth);
    
    float zoomLevel = maxWidthBlocks / blocks;
    
    float tileStartX = floorf(tileX/tileWidth)*tileWidth;
    float tileStartY = floorf(tileY/tileHeight)*tileHeight;

    MKMapRect visibleMapRect = MKMapRectMake(tileStartX, tileStartY, tileWidth*(blocks+1), tileHeight*(blocks+1));
    
    for (id<MKAnnotation> point in pins) {
        MKMapPoint mapPoint = MKMapPointForCoordinate(point.coordinate);
        
        if (MKMapRectContainsPoint(visibleMapRect, mapPoint)) {
            if (![mapView.annotations containsObject:point]) {
                [visibleAnnotations addObject:point];
            }   
        }
    }
    
    if( zoomLevel > minClusterLevel ){
        return visibleAnnotations;
    }
    
    NSMutableArray *clusteredBlocks = [NSMutableArray array];
    int i = 0;
    int length = (blocks+1)*(blocks+1);
    for ( ; i < length ; i ++ )
    {
        REVClusterBlock *block = [[REVClusterBlock alloc] init];
        [clusteredBlocks addObject:block];
        #if !__has_feature(objc_arc)
        [block release];  
        #endif
    }
    
    for (REVClusterPin *pin in visibleAnnotations)
    {
        MKMapPoint mapPoint = MKMapPointForCoordinate(pin.coordinate);
        
        double localPointX = mapPoint.x - tileStartX;
        double localPointY = mapPoint.y - tileStartY;
        
        int localTileNumberX = floor( localPointX / tileWidth );
        int localTileNumberY = floor( localPointY / tileHeight );
        int localTileNumber = localTileNumberX + (localTileNumberY * (blocks+1));
        
        [(REVClusterBlock *)[clusteredBlocks objectAtIndex:localTileNumber] addAnnotation:pin];
    }
    
    //create New Pins
    NSMutableArray *newPins = [NSMutableArray array];
    for ( REVClusterBlock *block in clusteredBlocks )
    {
        if( [block count] > 0 )
        {
            if( ![REVClusterManager clusterAlreadyExistsForMapView:mapView andBlockCluster:block] )
            {
              [newPins addObject:[block getClusteredAnnotation]];
            } 
        }
    }
    return newPins;
}

+ (BOOL) clusterAlreadyExistsForMapView:(MKMapView *)mapView andBlockCluster:(REVClusterBlock *)cluster
{
    for ( REVClusterPin *pin in mapView.annotations )
    {
        if( [pin isKindOfClass:[REVClusterPin class]] && [[pin nodes] count] > 0 )
        {
            MKMapPoint point1 =  MKMapPointForCoordinate([pin coordinate]);
            MKMapPoint point2 =  MKMapPointForCoordinate([[cluster getClusteredAnnotation] coordinate]);
            
            if( MKMapPointEqualToPoint(point1,point2) )
            {
                return YES;
            }
        }
    }
    return NO;
}

+ (NSArray *) clusterForMapView:(MKMapView *)mapView forAnnotations:(NSArray *)pins
{
    REVClusterMapView *rMapView = (REVClusterMapView*) mapView;
    return [self clusterAnnotationsForMapView:mapView forAnnotations:pins blocks:rMapView.blocks minClusterLevel:MINIMUM_CLUSTER_LEVEL];
}

+ (MKPolygon *)polygonForMapRect:(MKMapRect)mapRect
{
    MKMapPoint mapRectPoints[5]={
        MKMapPointMake(mapRect.origin.x, mapRect.origin.y),
        MKMapPointMake(mapRect.origin.x+mapRect.size.width, mapRect.origin.y),
        MKMapPointMake(mapRect.origin.x+mapRect.size.width, mapRect.origin.y+mapRect.size.height),
        MKMapPointMake(mapRect.origin.x, mapRect.origin.y+mapRect.size.height),
        
        MKMapPointMake(mapRect.origin.x, mapRect.origin.y)
    };
    return [MKPolygon polygonWithPoints:mapRectPoints count:5];
}

- (NSInteger)getGlobalTileNumberFromMapView:(MKMapView *)mapView forLocalTileNumber:(NSInteger)tileNumber
{
    REVClusterMapView *rMapView = (REVClusterMapView*) mapView;
    int blocks = rMapView.blocks;
    
    double tileX = mapView.visibleMapRect.origin.x;
    double tileY = mapView.visibleMapRect.origin.y;
    double tileWidth = mapView.visibleMapRect.size.width/blocks;
    double tileHeight = mapView.visibleMapRect.size.height/blocks;
    
    
    MKMapRect mapRect = MKMapRectWorld;
    NSUInteger maxWidthBlocks = round(mapRect.size.width / tileWidth);
    NSUInteger maxHeightBlocks = round(mapRect.size.height / tileHeight);
    
    double tileStartX = floor((tileX/mapRect.size.width) * maxWidthBlocks)*tileWidth;
    double tileStartY = floor((tileY/mapRect.size.height) * maxHeightBlocks)*tileHeight;
    
    double currentTileX = tileStartX + (tileWidth * (tileNumber % (blocks+1)));
    double currentTileY = tileStartY + (tileHeight * floor(tileNumber/(blocks+1)));
    
    NSInteger g = round((currentTileY / tileHeight) * maxWidthBlocks);
    g += round(currentTileX / tileWidth);
    
    return g;
    
}

@end
