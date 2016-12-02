//
//  GYFileEditInputAccessoryView.h
//  Pocket Assembly
//
//  Created by Guanqing Yan on 1/16/15.
//  Copyright (c) 2015 G. Yan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PAFileEditInputAccessoryViewDelegate <NSObject>
-(void)addString:(NSString*)text;
@end

@interface PAFileEditInputAccessoryView : UIView<UIInputViewAudioFeedback>
@property (nonatomic,assign) NSObject<PAFileEditInputAccessoryViewDelegate>* delegate;
@end
