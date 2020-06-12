//
//  AliyunVodSlider.m
//

#import "AliyunPlayerViewSlider.h"

@interface AliyunPlayerViewSlider()
@property(nonatomic, assign) CGFloat changedValue;

@end

@implementation AliyunPlayerViewSlider


- (instancetype)init{
    
    if (self =[super init]) {
    
        
        UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(press:)];
        pressGesture.minimumPressDuration = 0.01;
        
        [self addGestureRecognizer:pressGesture];
    
        
    }
    return self;
}

- (void)press:(UITapGestureRecognizer*)press {
    
    CGPoint touchPoint = [press locationInView:self];
    CGFloat value = (self.maximumValue - self.minimumValue) * (touchPoint.x / self.frame.size.width );
    if (value <0) {
        value = 0;
    }else if (value >1){
        value = 1;
    }
    
    switch (press.state) {
        case UIGestureRecognizerStateBegan:
            _beginPressValue = self.value;
            if ([self.sliderDelegate respondsToSelector:@selector(aliyunPlayerViewSlider:event:clickedSlider:)] ) {
                [self.sliderDelegate aliyunPlayerViewSlider:self event:UIControlEventTouchDown clickedSlider:value];
            }
            
            break;
        case UIGestureRecognizerStateChanged:
            _changedValue = value;
            if ([self.sliderDelegate respondsToSelector:@selector(aliyunPlayerViewSlider:event:clickedSlider:)] ) {
                [self.sliderDelegate aliyunPlayerViewSlider:self event:UIControlEventValueChanged clickedSlider:value];
                
            }
            
            break;
        case UIGestureRecognizerStateEnded:
            
            if ([self.sliderDelegate respondsToSelector:@selector(aliyunPlayerViewSlider:event:clickedSlider:)] ) {
                [self.sliderDelegate aliyunPlayerViewSlider:self event:UIControlEventTouchUpInside clickedSlider:value];
            }
            
             break;
        case UIGestureRecognizerStateFailed:{
            
        }
            break;
            
        case UIGestureRecognizerStateCancelled:{
          
            if ([self.sliderDelegate respondsToSelector:@selector(aliyunPlayerViewSlider:event:clickedSlider:)] ) {
                [self.sliderDelegate aliyunPlayerViewSlider:self event:UIControlEventTouchUpInside clickedSlider:_changedValue];
            }
            
        }
            break;
            
        default:
            break;
    }
    
    
    
             
}





@end
