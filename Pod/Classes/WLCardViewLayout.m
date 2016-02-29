//
//  WLCardViewLayout.h
//  WLCardViewLayout
//
//  Created by 巫龙 on 2/29/16.
//  Copyright (c) 2016 WonderLand. All rights reserved.
//

#import "WLCardViewLayout.h"
typedef NS_ENUM(NSInteger, WLSwipeToDeleteLayoutState){
    WLSwipeToDeleteLayoutStateNone,
    WLSwipeToDeleteLayoutStateDragging,
    WLSwipeToDeleteLayoutStateTransitionToEnd,
    WLSwipeToDeleteLayoutStateTransitionToStart,
    WLSwipeToDeleteLayoutStateDeleting
};
static CGFloat const kFadeConstant = M_PI; //Higher values causes the fade to happen quicker
static NSString * const kLSCollectionViewKeyPath = @"collectionView";
static CGFloat easingDisplacementFade(CGFloat ratio) {
    return fmaxf(pow(kFadeConstant,ratio)/kFadeConstant, 0.01f);
};

@interface WLCardViewLayout () <UIGestureRecognizerDelegate>
{
    CGPoint panGesturetranslation;
    NSIndexPath *selectedIndexPath;
    WLSwipeToDeleteDirection userTriggerredSwipeToDeleteDirection;
}
@property (nonatomic, assign) WLSwipeToDeleteLayoutState state;
@end

@implementation WLCardViewLayout
{
    CGFloat previousOffset;
    NSIndexPath *mainIndexPath;
    NSIndexPath *movingInIndexPath;
    CGFloat difference;
    

}
#pragma mark - init from nib (可视初始化)
-(void)awakeFromNib
{
    if (self.collectionView != nil) {
        self.deletionDistanceTresholdValue = WLSwipeToDeleteCollectionViewLayoutDefaultDeletionDistanceTresholdValue;
        self.deletionVelocityTresholdValue = WLSwipeToDeleteCollectionViewLayoutDefaultDeletionVelocityTresholdValue;
        self.swipeToDeleteDirection = WLSwipeToDeleteDirectionMin;

        [self setupCollectionView];
    }

}



- (void)setupLayout
{
    CGFloat inset  =  20;
    inset = floor(inset);

    self.itemSize = CGSizeMake(self.collectionView.bounds.size.width - 2*inset , self.collectionView.bounds.size.height );
    self.sectionInset = UIEdgeInsetsMake(0,inset, 0,inset);
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}

- (void)setupCollectionView {
    
    if(_panGestureRecognizer == nil){
        
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        [_panGestureRecognizer addObserver:self forKeyPath:@"delegate" options:NSKeyValueObservingOptionNew context:nil];
        _panGestureRecognizer.delegate = self;
        
    }
    
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_panGestureRecognizer];
        }
    }
    
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];
    
}


#pragma mark - layout core (布局实现)

- (void)prepareLayout
{
    [self setupLayout];
    [super prepareLayout];
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *attributes = [[NSMutableArray alloc]initWithArray:[super layoutAttributesForElementsInRect:rect]];
    
    NSArray *cellIndices = [self.collectionView indexPathsForVisibleItems];
    if(cellIndices.count == 0 )
    {
        return attributes;
    }
    else if (cellIndices.count == 1)
    {
        mainIndexPath = cellIndices.firstObject;
        movingInIndexPath = nil;
    }
    else if(cellIndices.count > 1)
    {
        NSIndexPath *firstIndexPath = cellIndices.firstObject;
        if(firstIndexPath == mainIndexPath)
        {
            movingInIndexPath = cellIndices[1];
        }
        else
        {
            movingInIndexPath = cellIndices.firstObject;
            mainIndexPath = cellIndices[1];
        }
        
    }
    
    difference =  self.collectionView.contentOffset.x - previousOffset;
    
    previousOffset = self.collectionView.contentOffset.x;
    
    for (UICollectionViewLayoutAttributes *attribute in attributes)
    {
        [self applyTransformToLayoutAttributes:attribute];
    }
    
    if (selectedIndexPath) {
        __block NSInteger selectedAttributesIndex = NSNotFound;
        
        [attributes enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attributes, NSUInteger idx, BOOL *stop) {
            if ([attributes.indexPath isEqual:selectedIndexPath]) {
                selectedAttributesIndex = idx;
                *stop = YES;
            }
        }];
        
        if (selectedAttributesIndex != NSNotFound) {
            UICollectionViewLayoutAttributes *selectedAttributes = [self layoutAttributesForItemAtIndexPath:selectedIndexPath];
            [attributes replaceObjectAtIndex:selectedAttributesIndex withObject:selectedAttributes];
        }
    }
    
    
    return  attributes;
}



- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    [self applyTransformToLayoutAttributes:attributes];
    if ([attributes.indexPath isEqual:selectedIndexPath]) {
        CGPoint center = attributes.center;
        [self applySelectedStateToAttributes:attributes];
        [self didDisplaceSelectedAttributes:attributes withInitialCenter:center];
    }

    return attributes;
}



#pragma mark - Gesture Recogniser (手势实现)

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    CGPoint velocity = [self.panGestureRecognizer velocityInView:[self.panGestureRecognizer view]];
    if ([gestureRecognizer isEqual:self.panGestureRecognizer]) {
        if (self.scrollDirection == UICollectionViewScrollDirectionVertical && fabs(velocity.x) > fabs(velocity.y)) {
            return YES;
        }else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal && fabs(velocity.y) > fabs(velocity.x)){
            return YES;
        }
    }
    return NO;
}


- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture{
    
    if(self.collectionView.allowsSelection == NO){
        return;
    }
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.state = WLSwipeToDeleteLayoutStateDragging;
            panGesturetranslation = [gesture translationInView:[gesture view]];
            CGPoint currentPoint = [gesture locationInView:[gesture view]];
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:currentPoint];
            if ([self.swipeToDeleteDelegate respondsToSelector:@selector(swipeToDeleteLayout:canDeleteCellAtIndexPath:)]) {
                if (![self.swipeToDeleteDelegate swipeToDeleteLayout:self canDeleteCellAtIndexPath:indexPath]) {
                    return;
                }
            }
            selectedIndexPath = indexPath;
            
            if ([self.swipeToDeleteDelegate respondsToSelector:@selector(swipeToDeleteLayout:willBeginDraggingCellAtIndexPath:)]) {
                [self.swipeToDeleteDelegate swipeToDeleteLayout:self willBeginDraggingCellAtIndexPath:selectedIndexPath];
            }
            
            [self invalidateLayout];
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            if (!selectedIndexPath) return;
            panGesturetranslation = [gesture translationInView:[gesture view]];
            CGPoint currentPoint = [gesture locationInView:[gesture view]];
            NSLog(@"%f",[gesture view].frame.origin.y);
            NSLog(@"%f",currentPoint.y);
            if (currentPoint.y < 0) {
                [self.panGestureRecognizer setEnabled:NO];
//                NSLog(@"out of rect");
               
            }
            [self cellDidTranslate];
            
            [self invalidateLayout];
            break;
        }
            
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            if (!selectedIndexPath) return;
            
            userTriggerredSwipeToDeleteDirection = [self deletionDirectionWithGestureRecogniser:gesture];
            BOOL shouldDelete = (userTriggerredSwipeToDeleteDirection != WLSwipeToDeleteDirectionNone);
            if ([self.swipeToDeleteDelegate respondsToSelector:@selector(swipeToDeleteLayout:willEndDraggingCellAtIndexPath:willDeleteCell:)]) {
                [self.swipeToDeleteDelegate swipeToDeleteLayout:self willEndDraggingCellAtIndexPath:selectedIndexPath willDeleteCell:shouldDelete];
            }
            
            __weak __typeof(self)weakSelf = self;
            
            void (^completionBlock)(BOOL finished) = ^(BOOL finished){
                if (finished) {
                    NSLog(@"swipe delete");
                    __typeof(weakSelf)strongSelf = weakSelf;
                    if ([strongSelf.swipeToDeleteDelegate respondsToSelector:@selector(swipeToDeleteLayout:didEndAnimationWithCellAtIndexPath:didDeleteCell:)]) {
                        [strongSelf.swipeToDeleteDelegate swipeToDeleteLayout:strongSelf didEndAnimationWithCellAtIndexPath:selectedIndexPath didDeleteCell:shouldDelete];
                    }
                    selectedIndexPath = nil;
                    userTriggerredSwipeToDeleteDirection = WLSwipeToDeleteDirectionNone;
                }
            };
            
            if (!shouldDelete || gesture.state == UIGestureRecognizerStateFailed  ) {
                [self cancelSwipeToDeleteWithCompletion:completionBlock];
            }else{
                NSArray *indexPathsToDelete = @[selectedIndexPath];
                [self performSwipeToDeleteForCellsAtIndexPaths:indexPathsToDelete withCompletion:completionBlock];
            }
            
            [self cellDidTranslate];
            
            break;
        }
            
        default:
            break;
    }
    
}

- (void)cellDidTranslate{
    if ([self.swipeToDeleteDelegate respondsToSelector:@selector(swipeToDeleteLayout:cellDidTranslateWithOffset:)]) {
        UICollectionViewLayoutAttributes *unselectedAttribute = [super layoutAttributesForItemAtIndexPath:selectedIndexPath];
        UICollectionViewLayoutAttributes *selectedAttribute = [self layoutAttributesForItemAtIndexPath:selectedIndexPath];
        UIOffset offset = UIOffsetMake(selectedAttribute.center.x - unselectedAttribute.center.x, selectedAttribute.center.y - unselectedAttribute.center.y);
        
        [self.swipeToDeleteDelegate swipeToDeleteLayout:self cellDidTranslateWithOffset:offset];
    }
}
#pragma mark - Helper of swipe out (滑动实现)

-(void)cancelSwipeToDeleteWithCompletion:(void (^)(BOOL finished))completionBlock{
    [self.panGestureRecognizer setEnabled:NO];
    if ([self.swipeToDeleteDelegate respondsToSelector:@selector(swipeToDeleteLayout:cellDidTranslateWithOffset:)]) {
        [self.swipeToDeleteDelegate swipeToDeleteLayout:self cellDidTranslateWithOffset:UIOffsetMake(0, 0)];
    }
    
    __weak __typeof(self)weakSelf = self;
    
    self.state = WLSwipeToDeleteLayoutStateTransitionToStart;
    [self clearSelectedIndexPaths];
    [self.collectionView performBatchUpdates:nil
                                  completion:^(BOOL finished) {
                                      __typeof(weakSelf)strongSelf = weakSelf;
                                      if (completionBlock) completionBlock(finished);
                                      strongSelf.state = WLSwipeToDeleteLayoutStateNone;
                                      [strongSelf.panGestureRecognizer setEnabled:YES];
                                  }];
}
-(void)performSwipeToDeleteForCellsAtIndexPaths:(NSArray *)indexPathsToDelete withCompletion:(void (^)(BOOL finished))completionBlock{
    [self.panGestureRecognizer setEnabled:NO];
    self.state = WLSwipeToDeleteLayoutStateTransitionToEnd;
    
    __weak __typeof(self)weakSelf = self;
    
    [self.collectionView performBatchUpdates:^{
        
    }  completion:^(BOOL finished) {
        
        __typeof(weakSelf)strongSelf = weakSelf;
        
        strongSelf.state = WLSwipeToDeleteLayoutStateDeleting;
        NSAssert(strongSelf.swipeToDeleteDelegate, @"No delegate found");
        [strongSelf.swipeToDeleteDelegate swipeToDeleteLayout:strongSelf didDeleteCellAtIndexPath:selectedIndexPath];
        [strongSelf clearSelectedIndexPaths];
        
        [strongSelf.collectionView performBatchUpdates:^{
            __typeof(weakSelf)strongSelf = weakSelf;
//            [strongSelf.collectionView deleteItemsAtIndexPaths:indexPathsToDelete];
            [strongSelf.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[indexPathsToDelete[0] section]]];

        }  completion:^(BOOL finished) {
            __typeof(weakSelf)strongSelf = weakSelf;
            
            if (completionBlock) completionBlock(finished);
            [strongSelf.panGestureRecognizer setEnabled:YES];
        }];
    }];
}

-(void)clearSelectedIndexPaths{
    selectedIndexPath = nil;
}

#pragma mark - Helper of postion final(滑动位置效果实现)

-(CGPoint)finalCenterPositionForAttributes:(UICollectionViewLayoutAttributes *)attributes{
    CGPoint finalCenterPosition = attributes.center;
    
    switch (userTriggerredSwipeToDeleteDirection) {
        case WLSwipeToDeleteDirectionMin:
        {
            if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
                finalCenterPosition.x = CGRectGetMinX(self.collectionView.bounds) - (attributes.frame.size.width/2.0f);
            }else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
                finalCenterPosition.y = CGRectGetMinY(self.collectionView.bounds) - (attributes.frame.size.height/2.0f);
            }
            break;
        }
            
        case WLSwipeToDeleteDirectionMax:
        {
            if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
                finalCenterPosition.x = CGRectGetMaxX(self.collectionView.bounds) + (attributes.frame.size.width/2.0f);
            }else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
                finalCenterPosition.y = CGRectGetMaxY(self.collectionView.bounds) + (attributes.frame.size.height/2.0f);
            }
            break;
        }
            
        default:
            break;
    }
    
    return finalCenterPosition;
}

-(WLSwipeToDeleteDirection)deletionDirectionWithGestureRecogniser:(UIPanGestureRecognizer *)panGesture{
    WLSwipeToDeleteDirection direction = WLSwipeToDeleteDirectionNone;
    
    CGPoint tranlastion = [panGesture translationInView:[panGesture view]];
    CGPoint velocity = [panGesture velocityInView:[panGesture view]];
    CGFloat escapeDistance = [self translationValue];
    CGFloat escapeVelocity = [self velocityMagnitude];
    
    if (escapeDistance > self.deletionDistanceTresholdValue && [self isTranslationInDeletionDirection:tranlastion]) {
        direction = [self swipeToDeleteDirectionFromValue:tranlastion];
    }else if (escapeVelocity > self.deletionVelocityTresholdValue && [self isVelocityInDeletionDirection:velocity]){
        direction = [self swipeToDeleteDirectionFromValue:tranlastion];
    }
    
    return direction;
}

-(CGFloat)translationValue{
    CGFloat tranlationValue = 0.0f;
    
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
        tranlationValue = panGesturetranslation.x;
    }else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        tranlationValue = panGesturetranslation.y;
    }
    
    return fabs(tranlationValue);
}

-(CGFloat)velocityMagnitude{
    
    return fabs([self velocity]);
}

-(CGFloat)velocity{
    
    CGPoint velocity = [self.panGestureRecognizer velocityInView:[self.panGestureRecognizer view]];
    CGFloat velocityValue = 0.0f;
    
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
        velocityValue = velocity.x;
    }else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        velocityValue = velocity.y;
    }
    return velocityValue;
    
}

-(WLSwipeToDeleteDirection)swipeToDeleteDirectionFromValue:(CGPoint)value{
    
    WLSwipeToDeleteDirection direction = WLSwipeToDeleteDirectionNone;
    
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
        if (value.x < 0) {
            direction = WLSwipeToDeleteDirectionMin;
        }else if (value.x > 0){
            direction = WLSwipeToDeleteDirectionMax;
        }
    }else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        if (value.y < 0) {
            direction = WLSwipeToDeleteDirectionMin;
        }else if (value.y > 0){
            direction = WLSwipeToDeleteDirectionMax;
        }
    }
    
    return direction;
}

-(BOOL)isVelocityInDeletionDirection:(CGPoint)velocity{
    
    WLSwipeToDeleteDirection userTriggerredSwipeToDeleteVelocityDirection = [self swipeToDeleteDirectionFromValue:velocity];
    BOOL inDeletionDirection = (self.swipeToDeleteDirection & userTriggerredSwipeToDeleteVelocityDirection);
    
    if (userTriggerredSwipeToDeleteVelocityDirection == WLSwipeToDeleteDirectionNone) {
        inDeletionDirection = NO;
    }
    
    return inDeletionDirection;
}

-(BOOL)isTranslationInDeletionDirection:(CGPoint)translation{
    
    WLSwipeToDeleteDirection userTriggerredSwipeToDeleteTranslationDirection = [self swipeToDeleteDirectionFromValue:translation];
    BOOL inDeletionDirection = (self.swipeToDeleteDirection & userTriggerredSwipeToDeleteTranslationDirection);
    
    if (userTriggerredSwipeToDeleteTranslationDirection == WLSwipeToDeleteDirectionNone) {
        inDeletionDirection = NO;
    }
    
    return inDeletionDirection;
}
- (void)didDisplaceSelectedAttributes:(UICollectionViewLayoutAttributes *)attributes withInitialCenter:(CGPoint)initialCenter {
    CGPoint center = attributes.center;
    
    if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
        CGFloat middle = initialCenter.y;
        CGFloat displacementRatio = (center.y <= middle? (center.y/middle): ((middle - (center.y - middle))/middle));
        CGFloat alpha = easingDisplacementFade(displacementRatio);
        attributes.alpha = alpha;
    }
    else {
        CGFloat middle = initialCenter.x;
        CGFloat displacementRatio = (center.x <= middle? (center.x/middle): ((middle - (center.x - middle))/middle));
        CGFloat alpha = easingDisplacementFade(displacementRatio);
        attributes.alpha = alpha;
    }
}

// indicate that we want to redraw as we scroll
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

#pragma mark - card swipe (卡片滑动效果实现)

- (void)applyTransformToLayoutAttributes:(UICollectionViewLayoutAttributes *)attribute
{
    if(attribute.indexPath.section == mainIndexPath.section)
    {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:mainIndexPath];
        attribute.transform3D = [self transformFromView:cell];
        
    }
    else if (attribute.indexPath.section == movingInIndexPath.section)
    {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:movingInIndexPath];
        attribute.transform3D = [self transformFromView:cell];
    }
}

-(void)applySelectedStateToAttributes:(UICollectionViewLayoutAttributes *)attributes{
    CGPoint center = attributes.center;
    
    CGFloat minCenterX = center.x;
    CGFloat minCenterY = center.y;
    CGFloat maxCenterX = center.x;
    CGFloat maxCenterY = center.y;
    
    if (self.swipeToDeleteDirection & WLSwipeToDeleteDirectionMin) {
        minCenterX = - MAXFLOAT;
        minCenterY = - MAXFLOAT;
    }
    
    if (self.swipeToDeleteDirection & WLSwipeToDeleteDirectionMax) {
        maxCenterX = MAXFLOAT;
        maxCenterY = MAXFLOAT;
    }
    
    if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
        center.x = MAX(minCenterX, MIN(maxCenterX, center.x + panGesturetranslation.x));
    }else if (self.scrollDirection == UICollectionViewScrollDirectionHorizontal){
        center.y = MAX(minCenterY, MIN(maxCenterY, center.y + panGesturetranslation.y));

    }
    
    if (self.state == WLSwipeToDeleteLayoutStateTransitionToEnd) {
        center = [self finalCenterPositionForAttributes:attributes];
    }
    
    attributes.center = center;
}




#pragma mark - Logica
- (CGFloat)baseOffsetForView:(UIView *)view
{
    UICollectionViewCell *cell = (UICollectionViewCell *)view;
    CGFloat offset =  ([self.collectionView indexPathForCell:cell].section) * self.collectionView.bounds.size.width;
    
    return offset;
}

- (CGFloat)heightOffsetForView:(UIView *)view
{
    CGFloat height;
    CGFloat baseOffsetForCurrentView = [self baseOffsetForView:view ];
    CGFloat currentOffset = self.collectionView.contentOffset.x;
    CGFloat scrollViewWidth = self.collectionView.bounds.size.width;
    //TODO:make this constant a certain proportion of the collection view
    height = 120 * (currentOffset - baseOffsetForCurrentView)/scrollViewWidth;
    if(height < 0 )
    {
        height = - 1 * height;
    }
    return height;
}

- (CGFloat)angleForView:(UIView *)view
{
    CGFloat baseOffsetForCurrentView = [self baseOffsetForView:view ];
    CGFloat currentOffset = self.collectionView.contentOffset.x;
    CGFloat scrollViewWidth = self.collectionView.bounds.size.width;
    CGFloat angle = (currentOffset - baseOffsetForCurrentView)/scrollViewWidth;
    return angle;
}

- (BOOL)xAxisForView:(UIView *)view
{
    CGFloat baseOffsetForCurrentView = [self baseOffsetForView:view ];
    CGFloat currentOffset = self.collectionView.contentOffset.x;
    CGFloat offset = (currentOffset - baseOffsetForCurrentView);
    if(offset >= 0)
    {
        return YES;
    }
    return NO;    
}


#pragma mark - Transform Related Calculation (滑动形变的实现)

- (CATransform3D)transformFromView:(UIView *)view
{
    CGFloat angle = [self angleForView:view];
    CGFloat height = [self heightOffsetForView:view];
    BOOL xAxis = [self xAxisForView:view];
    return [self transformfromAngle:angle height:height xAxis:xAxis];
}

- (CATransform3D)transformfromAngle:(CGFloat)angle height:(CGFloat)height xAxis:(BOOL)axis
{
    CATransform3D t = CATransform3DIdentity;
    t.m34  = 1.0/-500;
    
    if (axis)
    {
        t = CATransform3DRotate(t,angle*0.3, 1, 1, 0);
    }
    else
    {
        t = CATransform3DRotate(t,angle*0.3, -1, 1, 0);
    }
    
    return t;
}
#pragma mark - Key-Value Observing methods (监听)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kLSCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        }
    }else if ([keyPath isEqualToString:@"delegate"] && [object isEqual:self.panGestureRecognizer]){
        NSAssert([[change objectForKey:NSKeyValueChangeNewKey] isEqual:self], @"The delegate of the PanGestureRecogniser must be the layout object");
    }
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:kLSCollectionViewKeyPath];
    [_panGestureRecognizer removeObserver:self forKeyPath:@"delegate"];
}

@end

