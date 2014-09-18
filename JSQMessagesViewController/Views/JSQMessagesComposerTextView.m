//
//  Created by Jesse Squires
//  http://www.hexedbits.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQMessagesComposerTextView.h"

#import <QuartzCore/QuartzCore.h>

#import "NSString+JSQMessages.h"
#import "JSQMessagesToolbarContentView.h"


@interface JSQMessagesComposerTextView ()

- (void)jsq_configureTextView;

- (void)jsq_addTextViewNotificationObservers;
- (void)jsq_removeTextViewNotificationObservers;
- (void)jsq_didReceiveTextViewNotification:(NSNotification *)notification;

- (NSDictionary *)jsq_placeholderTextAttributes;

@end



@implementation JSQMessagesComposerTextView

#pragma mark - Initialization

- (void)jsq_configureTextView
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    CGFloat cornerRadius = 6.0f;
    
    self.backgroundColor = [UIColor whiteColor];
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.cornerRadius = cornerRadius;
    
    self.scrollIndicatorInsets = UIEdgeInsetsMake(cornerRadius, 0.0f, cornerRadius, 0.0f);
    
    self.textContainerInset = UIEdgeInsetsMake(4.0f, 2.0f, 4.0f, 2.0f);
    self.contentInset = UIEdgeInsetsMake(2.0f, 0.0f, 2.0f, 0.0f);
    
    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    self.userInteractionEnabled = YES;
    
    self.font = [UIFont systemFontOfSize:16.0f];
    self.textColor = [UIColor blackColor];
    self.textAlignment = NSTextAlignmentLeft;
    
    self.contentMode = UIViewContentModeRedraw;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.keyboardAppearance = UIKeyboardAppearanceDefault;
    self.keyboardType = UIKeyboardTypeDefault;
    self.returnKeyType = UIReturnKeySend;
    
    self.text = nil;
    
    _placeHolder = nil;
    _placeHolderTextColor = [UIColor lightGrayColor];
    
    [self jsq_addTextViewNotificationObservers];
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self jsq_configureTextView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self jsq_configureTextView];
}

- (void)dealloc
{
    [self jsq_removeTextViewNotificationObservers];
    _placeHolder = nil;
    _placeHolderTextColor = nil;
}

#pragma mark - Composer text view

- (BOOL)hasText
{
    return ([[self.text jsq_stringByTrimingWhitespace] length] > 0);
}

#pragma mark - Setters

- (void)setPlaceHolder:(NSString *)placeHolder
{
    if ([placeHolder isEqualToString:_placeHolder]) {
        return;
    }
    
    _placeHolder = [placeHolder copy];
    [self setNeedsDisplay];
}

- (void)setPlaceHolderTextColor:(UIColor *)placeHolderTextColor
{
    if ([placeHolderTextColor isEqual:_placeHolderTextColor]) {
        return;
    }
    
    _placeHolderTextColor = placeHolderTextColor;
    [self setNeedsDisplay];
}

#pragma mark - UITextView overrides

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self setNeedsDisplay];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (void)textViewDidBeginEditing:(NSNotification *)notification {
    if ([self.text isEqualToString:self.placeHolder]) {
        self.textColor = [UIColor colorWithRed:160/255.0 green:160/255.0 blue:160/255.0 alpha:1.0];
        self.text = @"";
    }
    
    CGFloat topCorrect = ([self bounds].size.height - [self contentSize].height * [self zoomScale])/2.0;
    topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
    self.contentOffset = (CGPoint){ .x = 0, .y = -topCorrect };
}

- (void)textViewDidEndEditing:(NSNotification *)notification {
    if ([self.text length] == 0 && self.placeHolder) {
        self.textColor = self.placeHolderTextColor;
        self.text = self.placeHolder;
    }
    CGFloat topCorrect = ([self bounds].size.height - [self contentSize].height * [self zoomScale])/2.0;
    topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
    self.contentOffset = (CGPoint){ .x = 0, .y = -topCorrect };
}

- (void)textViewDidChange:(NSNotification *)notification {
    if([self.text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound ) {
        // send message
    
        self.text = [self.text substringToIndex:[self.text length] - 1];
        JSQMessagesToolbarContentView *contentView = (JSQMessagesToolbarContentView *)self.superview;
        [contentView sendButtonWasPressed:nil];
        
        
    }
}

#pragma mark - Notifications

- (void)jsq_addTextViewNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textViewDidChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textViewDidBeginEditing:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textViewDidEndEditing:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:self];
}

- (void)jsq_removeTextViewNotificationObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidChangeNotification
                                                  object:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidBeginEditingNotification
                                                  object:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextViewTextDidEndEditingNotification
                                                  object:self];
}

- (void)jsq_didReceiveTextViewNotification:(NSNotification *)notification
{
    [self setNeedsDisplay];
}

#pragma mark - Utilities

- (NSDictionary *)jsq_placeholderTextAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = self.textAlignment;
    
    return @{ NSFontAttributeName : self.font,
              NSForegroundColorAttributeName : self.placeHolderTextColor,
              NSParagraphStyleAttributeName : paragraphStyle };
}

- (UIViewController*) currentController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

@end
