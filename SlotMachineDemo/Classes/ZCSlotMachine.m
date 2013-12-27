
#import <QuartzCore/QuartzCore.h>

#import "ZCSlotMachine.h"

#define SHOW_BORDER 0

static BOOL isSliding = NO;
static const NSUInteger kMinTurn = 3;
static NSString * const keyPath = @"position.y";

static const NSUInteger kLoadingDuration = 3;
static const NSUInteger kStopDuration = 3;

/********************************************************************************************/

@implementation ZCSlotMachine {
 @private
    // UI
    UIImageView *_backgroundImageView;
    UIImageView *_coverImageView;
    UIView *_contentView;
    UIEdgeInsets _contentInset;
    NSMutableArray *_slotScrollLayerArray;
    
    // Data
    NSArray *_slotResults;
    NSArray *_currentSlotResults;
    
    __weak id<ZCSlotMachineDataSource> _dataSource;
    
    BOOL _isTimeout;
    NSArray *_realResults;
    NSMutableArray *_completePositionArray;
}

#pragma mark - View LifeCycle

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        _backgroundImageView = [[UIImageView alloc] initWithFrame:frame];
#warning TODO:chenms:为测试暂时改了mode，改为默认拉伸
//        _backgroundImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_backgroundImageView];
        
        _contentView = [[UIView alloc] initWithFrame:frame];
#if SHOW_BORDER
        _contentView.layer.borderColor = [UIColor blueColor].CGColor;
        _contentView.layer.borderWidth = 1;
#endif
        
        [self addSubview:_contentView];
        
        _coverImageView = [[UIImageView alloc] initWithFrame:frame];
        _coverImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_coverImageView];
        
        _slotScrollLayerArray = [NSMutableArray array];
        
        self.singleUnitDuration = 0.14f;
        
        _contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    return self;
}

#pragma mark - Properties Methods
- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImageView.image = backgroundImage;
}
- (void)setCoverImage:(UIImage *)coverImage {
    _coverImageView.image = coverImage;
}
- (UIEdgeInsets)contentInset {
    return _contentInset;
}
- (void)setContentInset:(UIEdgeInsets)contentInset {
    _contentInset = contentInset;
    
    CGRect viewFrame = self.frame;
    
    _contentView.frame = CGRectMake(_contentInset.left, _contentInset.top, viewFrame.size.width - _contentInset.left - _contentInset.right, viewFrame.size.height - _contentInset.top - _contentInset.bottom);
}
- (NSArray *)slotResults {
    return _slotResults;
}
- (void)setSlotResults:(NSArray *)slotResults {
    if (!isSliding) {
        _slotResults = slotResults;
        
        if (!_currentSlotResults) {
            NSMutableArray *currentSlotResults = [NSMutableArray array];
            for (int i = 0; i < [slotResults count]; i++) {
                [currentSlotResults addObject:[NSNumber numberWithUnsignedInteger:0]];
            }
            _currentSlotResults = [NSArray arrayWithArray:currentSlotResults];
        }
    }
}
- (id<ZCSlotMachineDataSource>)dataSource {
    return _dataSource;
}
- (void)setDataSource:(id<ZCSlotMachineDataSource>)dataSource {
    _dataSource = dataSource;
    
    [self reloadData];
}

#pragma mark - reloadData
- (void)reloadData {
    if (self.dataSource) {
        for (CALayer *containerLayer in _contentView.layer.sublayers) {
            [containerLayer removeFromSuperlayer];
        }
        _slotScrollLayerArray = [NSMutableArray array];
        
        NSUInteger numberOfSlots = [self.dataSource numberOfSlotsInSlotMachine:self];
        CGFloat slotSpacing = 0;
        if ([self.dataSource respondsToSelector:@selector(slotSpacingInSlotMachine:)]) {
            slotSpacing = [self.dataSource slotSpacingInSlotMachine:self];
        }
        
        CGFloat slotWidth = _contentView.frame.size.width / numberOfSlots;
        if ([self.dataSource respondsToSelector:@selector(slotWidthInSlotMachine:)]) {
            slotWidth = [self.dataSource slotWidthInSlotMachine:self];
        }
        
        for (int i = 0; i < numberOfSlots; i++) {
            CALayer *slotContainerLayer = [[CALayer alloc] init];
            slotContainerLayer.frame = CGRectMake(i * (slotWidth + slotSpacing), 0, slotWidth, _contentView.frame.size.height);
            slotContainerLayer.masksToBounds = YES;
            
            CALayer *slotScrollLayer = [[CALayer alloc] init];
            slotScrollLayer.frame = CGRectMake(0, 0, slotWidth, _contentView.frame.size.height);
#if SHOW_BORDER
            slotScrollLayer.borderColor = [UIColor greenColor].CGColor;
            slotScrollLayer.borderWidth = 1;
#endif
            [slotContainerLayer addSublayer:slotScrollLayer];
            
            [_contentView.layer addSublayer:slotContainerLayer];
            
            [_slotScrollLayerArray addObject:slotScrollLayer];
        }
        
        CGFloat singleUnitHeight = _contentView.frame.size.height / 3;
        
        NSArray *slotIcons = [self.dataSource iconsForSlotsInSlotMachine:self];
        NSUInteger iconCount = [slotIcons count];
        
        for (int i = 0; i < numberOfSlots; i++) {
            CALayer *slotScrollLayer = [_slotScrollLayerArray objectAtIndex:i];
            NSInteger scrollLayerTopIndex = - (i + kMinTurn + 3) * iconCount;
            
            for (int j = 0; j > scrollLayerTopIndex; j--) {
                UIImage *iconImage = [slotIcons objectAtIndex:abs(j) % numberOfSlots];
                
                CALayer *iconImageLayer = [[CALayer alloc] init];
                // adjust the beginning offset of the first unit
                NSInteger offsetYUnit = j + 1 + iconCount;
                iconImageLayer.frame = CGRectMake(0, offsetYUnit * singleUnitHeight, slotScrollLayer.frame.size.width, singleUnitHeight);
                
                iconImageLayer.contents = (id)iconImage.CGImage;
                iconImageLayer.contentsScale = iconImage.scale;
                iconImageLayer.contentsGravity = kCAGravityCenter;
#if SHOW_BORDER
                iconImageLayer.borderColor = [UIColor redColor].CGColor;
                iconImageLayer.borderWidth = 1;
#endif
                
                [slotScrollLayer addSublayer:iconImageLayer];
            }
        }
    }
}

#pragma mark - slide
- (void)startSliding {
    if (isSliding) {
        return;
    }
    else {
        isSliding = YES;
        if ([self.delegate respondsToSelector:@selector(slotMachineWillStartSliding:)]) {
            [self.delegate slotMachineWillStartSliding:self];
        }
        
        // @chenms @2013-12-27
        // 每次开始slide时重置超时时间和真实结果
        // 超时时间：例如设置为3s
        // 第一列的3s动画结束后，就设置为超时了，因为这之后才拿到结果的话，再启动第2段动画旋转到结果icon，就太生硬了；
        [self setIsTimeout:NO];
        // 真实结果（_realResults），因为本控件slide需要提供一个结果，我们的真实结果是去服务端请求的；
        // 为了请求时就开始slide，我们在（前3s）先设置一个不中奖的默认结果，例如@[@0, @1, @2, @3]，
        // 在超时时间之内拿到结果的话，我们再在动画结束后接入第2段动画，转到真实结果处。
        _realResults = nil;
        
        NSArray *slotIcons = [self.dataSource iconsForSlotsInSlotMachine:self];
        NSUInteger slotIconsCount = [slotIcons count];
        
        _completePositionArray = [NSMutableArray array];
        
        for (int i = 0; i < [_slotScrollLayerArray count]; i++) {
            // @chenms @2013-12-27
            // 原作中是N列的动画在一个事务里
            // 修改版因为每列都要在合适的时间接入第2段动画，故每列置入一个事务
            [CATransaction begin];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
            [CATransaction setDisableActions:YES];
            [CATransaction setCompletionBlock:^{
                [self onLoadingAnimaFinish:@(i)];
            }];
            CALayer *slotScrollLayer = [_slotScrollLayerArray objectAtIndex:i];
            
            NSUInteger resultIndex = [[self.slotResults objectAtIndex:i] unsignedIntegerValue];
            NSUInteger currentIndex = [[_currentSlotResults objectAtIndex:i] unsignedIntegerValue];
        
            NSUInteger howManyUnit = (i + kMinTurn) * slotIconsCount + resultIndex - currentIndex;
            CGFloat slideY = howManyUnit * (_contentView.frame.size.height / 3);
            
            CABasicAnimation *slideAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
            slideAnimation.fillMode = kCAFillModeForwards;
            slideAnimation.duration = howManyUnit * self.singleUnitDuration;
            slideAnimation.toValue = [NSNumber numberWithFloat:slotScrollLayer.position.y + slideY];
            slideAnimation.removedOnCompletion = NO;
            
            [slotScrollLayer addAnimation:slideAnimation forKey:@"slideAnimation"];
            
            [_completePositionArray addObject:slideAnimation.toValue];
            [CATransaction commit];
        }
    }
}

- (void)onLoadingAnimaFinish:(NSNumber*)indexObj{
    int i = [indexObj intValue];
    
    // @chenms @2013-12-27
    // 第一列的动画结束时，设置为超时，此后从服务端返回的摇奖结果，将被忽略
    // 当然，这可能会造成服务端和客户端摇奖结果不一致；但合理设置动画时间，应该能将几率降到很低。
    if (i == 0) {
        [self setIsTimeout:YES];
    }

    NSArray *slotIcons = [self.dataSource iconsForSlotsInSlotMachine:self];
    NSUInteger slotIconsCount = [slotIcons count];
    
    CALayer *slotScrollLayer = [_slotScrollLayerArray objectAtIndex:i];
    slotScrollLayer.position = CGPointMake(slotScrollLayer.position.x, ((NSNumber *)[_completePositionArray objectAtIndex:i]).floatValue);
    NSMutableArray *toBeDeletedLayerArray = [NSMutableArray array];
    NSUInteger resultIndex = [[self.slotResults objectAtIndex:i] unsignedIntegerValue];
    NSUInteger currentIndex = [[_currentSlotResults objectAtIndex:i] unsignedIntegerValue];

    for (int j = 0; j < slotIconsCount * (kMinTurn + i) + resultIndex - currentIndex; j++) {
        CALayer *iconLayer = [slotScrollLayer.sublayers objectAtIndex:j];
        [toBeDeletedLayerArray addObject:iconLayer];
    }

    // @chenms @2013-15-41
    // layer的add和remove都有隐式动画，需要在事务中用setDisableActions屏蔽掉；
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    @autoreleasepool {
        for (CALayer *toBeDeletedLayer in toBeDeletedLayerArray) {
            // use initWithLayer does not work
            CALayer *toBeAddedLayer = [CALayer layer];
            toBeAddedLayer.frame = toBeDeletedLayer.frame;
            toBeAddedLayer.contents = toBeDeletedLayer.contents;
            toBeAddedLayer.contentsScale = toBeDeletedLayer.contentsScale;
            toBeAddedLayer.contentsGravity = toBeDeletedLayer.contentsGravity;
            CGFloat shiftY = slotIconsCount * toBeAddedLayer.frame.size.height * (kMinTurn + i + 3);
            toBeAddedLayer.position = CGPointMake(toBeAddedLayer.position.x, toBeAddedLayer.position.y - shiftY);
            
//            CGFloat shiftY = slotIconsCount * toBeDeletedLayer.frame.size.height * (kMinTurn + i + 3);
//            toBeDeletedLayer.position = CGPointMake(toBeDeletedLayer.position.x, toBeDeletedLayer.position.y - shiftY);
            
            [toBeDeletedLayer removeFromSuperlayer];
            [slotScrollLayer addSublayer:toBeAddedLayer];
        }
    }
    [CATransaction commit];

    // @chenms @2013-12-27
    // 真实结果不存在的话，就没必要接入第2段动画了；
    // 在最慢的列结束后，做些后置处理
    if (!_realResults || _realResults.count <= 0) {
        if (i == slotIcons.count - 1
            && [self.delegate respondsToSelector:@selector(slotMachineDidEndSliding:)]) {
            _currentSlotResults = [self.slotResults copy];
            [self.delegate slotMachineDidEndSliding:self];
            isSliding = NO;
        }
        return;
    }
    
    // 有真实结果，则接入第2段动画
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    [CATransaction setDisableActions:YES];
    [CATransaction setCompletionBlock:^{
        slotScrollLayer.position = CGPointMake(slotScrollLayer.position.x, ((NSNumber *)[_completePositionArray objectAtIndex:i]).floatValue);
        NSMutableArray *toBeDeletedLayerArray = [NSMutableArray array];
        NSUInteger resultIndex = [[_realResults objectAtIndex:i] unsignedIntegerValue];
        NSUInteger currentIndex = [[self.slotResults objectAtIndex:i] unsignedIntegerValue];
        for (int j = 0; j < (resultIndex - currentIndex + slotIconsCount) % slotIconsCount + slotIconsCount; j++) {
            CALayer *iconLayer = [slotScrollLayer.sublayers objectAtIndex:j];
            [toBeDeletedLayerArray addObject:iconLayer];
        }
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        @autoreleasepool {
            for (CALayer *toBeDeletedLayer in toBeDeletedLayerArray) {
                // use initWithLayer does not work
                CALayer *toBeAddedLayer = [CALayer layer];
                toBeAddedLayer.frame = toBeDeletedLayer.frame;
                toBeAddedLayer.contents = toBeDeletedLayer.contents;
                toBeAddedLayer.contentsScale = toBeDeletedLayer.contentsScale;
                toBeAddedLayer.contentsGravity = toBeDeletedLayer.contentsGravity;
                CGFloat shiftY = slotIconsCount * toBeAddedLayer.frame.size.height * (kMinTurn + i + 3);
                toBeAddedLayer.position = CGPointMake(toBeAddedLayer.position.x, toBeAddedLayer.position.y - shiftY);
                
//                CGFloat shiftY = slotIconsCount * toBeDeletedLayer.frame.size.height * (kMinTurn + i + 3);
//                toBeDeletedLayer.position = CGPointMake(toBeDeletedLayer.position.x, toBeDeletedLayer.position.y - shiftY);
                
                [toBeDeletedLayer removeFromSuperlayer];
                [slotScrollLayer addSublayer:toBeAddedLayer];
            }
        }
        [CATransaction commit];
        
        if (i == slotIcons.count - 1
            && [self.delegate respondsToSelector:@selector(slotMachineDidEndSliding:)]) {
            _currentSlotResults = [_realResults copy];
            [self.delegate slotMachineDidEndSliding:self];
            isSliding = NO;
        }
    }];
    currentIndex = [[self.slotResults objectAtIndex:i] unsignedIntegerValue];
    resultIndex = [[_realResults objectAtIndex:i] unsignedIntegerValue];
    // 保证至少转一圈，否则太生硬
    NSUInteger howManyUnit = (resultIndex - currentIndex + slotIconsCount) % slotIconsCount + slotIconsCount;
    CGFloat slideY = howManyUnit * (_contentView.frame.size.height / 3);
    CABasicAnimation *slideAnimation = [CABasicAnimation animationWithKeyPath:keyPath];
    slideAnimation.fillMode = kCAFillModeForwards;
    slideAnimation.duration = kStopDuration;
    slideAnimation.toValue = [NSNumber numberWithFloat:slotScrollLayer.position.y + slideY];
    slideAnimation.removedOnCompletion = NO;
    [slotScrollLayer addAnimation:slideAnimation forKey:@"slideAnimation"];
    [_completePositionArray replaceObjectAtIndex:i withObject: slideAnimation.toValue];
    [CATransaction commit];
}

#pragma mark -
#warning TODO:chenms:有小几率出现并发问题，但因为赋值操作很短暂，暂不加锁
- (void)trySetRealResults:(NSArray*)results{
//    @synchronized(self){
        if (!_isTimeout) {
            _realResults = results;
        }
//    NSLog(@"服务端响应(%@)  @@%s", _realResults, __func__);
//    }
}
- (NSArray*)realResults{
    return _realResults;
}

#pragma mark -
- (void)setIsTimeout:(BOOL)isTimeout{
//    @synchronized(self){
        _isTimeout = isTimeout;
//    }
}

@end
