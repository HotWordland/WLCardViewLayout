//
//  WLCardViewLayout.h
//  WLCardViewLayout
//
//  Created by 巫龙 on 2/29/16.
//  Copyright (c) 2016 WonderLand. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WLSwipeToDeleteDirection){
    WLSwipeToDeleteDirectionNone    =   1 << 0,      // prevents deletion
    WLSwipeToDeleteDirectionMin     =   1 << 1, // Causes deletion animation toward the CollectionView's bounds minX or minY
    WLSwipeToDeleteDirectionMax     =   1 << 2  // Causes deletion animation toward the CollectionView's bounds maxX or maxY
};
static const CGFloat WLSwipeToDeleteCollectionViewLayoutDefaultDeletionDistanceTresholdValue = 100.0f;
static const CGFloat WLSwipeToDeleteCollectionViewLayoutDefaultDeletionVelocityTresholdValue = 100.0f;

@protocol WLSwipeToDeleteCollectionViewLayoutDelegate;


@interface WLCardViewLayout : UICollectionViewFlowLayout<UIGestureRecognizerDelegate>
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) CGFloat deletionDistanceTresholdValue;
@property (nonatomic, assign) CGFloat deletionVelocityTresholdValue;
@property (nonatomic, assign) WLSwipeToDeleteDirection swipeToDeleteDirection;
@property (nonatomic, assign) id <WLSwipeToDeleteCollectionViewLayoutDelegate> swipeToDeleteDelegate;

@end
@protocol WLSwipeToDeleteCollectionViewLayoutDelegate <NSObject>
/* 删除的代理 required method. The datasoures need to remove the object at the specified indexPath */
-(void)swipeToDeleteLayout:(WLCardViewLayout *)layout didDeleteCellAtIndexPath:(NSIndexPath *)indexPath;

@optional
/* 选择实现 */
/* return YES to allow the for deletion of the indexPath. Default is YES */
-(BOOL)swipeToDeleteLayout:(WLCardViewLayout *)layout canDeleteCellAtIndexPath:(NSIndexPath *)indexPath;
/* Called just after the pan to delete gesture is recognised with a proposed item for deletion. */
-(void)swipeToDeleteLayout:(WLCardViewLayout *)layout willBeginDraggingCellAtIndexPath:(NSIndexPath *)indexPath;
/* Called just after the user lift the finger and right before the deletion/restoration animation begins. */
-(void)swipeToDeleteLayout:(WLCardViewLayout *)layout willEndDraggingCellAtIndexPath:(NSIndexPath *)indexPath willDeleteCell:(BOOL)willDelete;
/* Called just after the deletion/restoration animation ended. */
-(void)swipeToDeleteLayout:(WLCardViewLayout *)layout didEndAnimationWithCellAtIndexPath:(NSIndexPath *)indexPath didDeleteCell:(BOOL)didDelete;
/* Provides the current point of the pan gesture received on the cell. 0,0 is the original center of the cell and the coordinate system follows the UIView coordinate system. You may also use the panGestureRecognizer property to get extract more information about the interaction */
-(void)swipeToDeleteLayout:(WLCardViewLayout *)layout cellDidTranslateWithOffset:(UIOffset)offset;
@end