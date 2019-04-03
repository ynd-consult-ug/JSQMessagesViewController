//
//  Created by Jesse Squires
//  http://www.jessesquires.com
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

@interface JSQMessagesComposerTextView()
@property (nonatomic, strong) NSArray<UIMenuItem *> *customMenuItems;
@property (nonatomic, strong) NSArray<UIMenuItem *> *customTextStyleOptions;
@property (nonatomic, weak) id customTarget;
@end

@implementation JSQMessagesComposerTextView

@synthesize pasteDelegate;

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
    self.contentInset = UIEdgeInsetsMake(1.0f, 0.0f, 1.0f, 0.0f);

    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    self.userInteractionEnabled = YES;

    self.font = [UIFont systemFontOfSize:16.0f];
    self.textColor = [UIColor blackColor];
    self.textAlignment = NSTextAlignmentNatural;

    self.contentMode = UIViewContentModeRedraw;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.keyboardAppearance = UIKeyboardAppearanceDefault;
    self.keyboardType = UIKeyboardTypeDefault;
    self.returnKeyType = UIReturnKeyDefault;

    self.text = nil;

    _placeHolder = nil;
    _placeHolderTextColor = [UIColor lightGrayColor];

    [self jsq_addTextViewNotificationObservers];
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        [self jsq_configureTextView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self jsq_configureTextView];
}

- (void)dealloc {
    [self jsq_removeTextViewNotificationObservers];
}

#pragma mark - Composer text view

- (BOOL)hasText {
    NSString *textWithoutWhitespaces = [self.text jsq_stringByTrimingWhitespace];
    /* TUN-7192 - send button is active when user double tap dictation button on keyboard.
     This is workaround to detect if UITextView has text provided by user. If user double click on dictation button, temporarly in text input system adds \U0000fffc character and displays spinner animation. Looks like this code is NSTextAttachement position indicatior. This causes problem because - (BOOL)hasText returns YES even if UITextView input looks empty. Fix for this issue is replace this character with empty string.
     */
    NSString *textAttachmentCharachter = @"\U0000fffc";
    NSString *finalText = [textWithoutWhitespaces stringByReplacingOccurrencesOfString:textAttachmentCharachter withString:@""];
    
    return ([finalText length] > 0);
}

#pragma mark - Setters

- (void)setPlaceHolder:(NSString *)placeHolder {
    if ([placeHolder isEqualToString:_placeHolder]) {
        return;
    }

    _placeHolder = [placeHolder copy];
    [self setNeedsDisplay];
}

- (void)setPlaceHolderTextColor:(UIColor *)placeHolderTextColor {
    if ([placeHolderTextColor isEqual:_placeHolderTextColor]) {
        return;
    }

    _placeHolderTextColor = placeHolderTextColor;
    [self setNeedsDisplay];
}

#pragma mark - UITextView overrides

- (void)setText:(NSString *)text {
    [super setText:text];
    [self setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    [super setAttributedText:attributedText];
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    [self setNeedsDisplay];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [super setTextAlignment:textAlignment];
    [self setNeedsDisplay];
}

- (void)paste:(id)sender {
    if (!self.pasteDelegate || [self.pasteDelegate composerTextView:self shouldPasteWithSender:sender]) {
        [super paste:sender];
    }
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if ([self.text length] == 0 && self.placeHolder) {
        [self.placeHolderTextColor set];

        [self.placeHolder drawInRect:CGRectInset(rect, 7.0f, 5.0f)
                      withAttributes:[self jsq_placeholderTextAttributes]];
    }
}

#pragma mark - Notifications

- (void)jsq_addTextViewNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidBeginEditingNotification
                                               object:self];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(jsq_didReceiveTextViewNotification:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:self];
}

- (void)jsq_removeTextViewNotificationObservers {
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

- (void)jsq_didReceiveTextViewNotification:(NSNotification *)notification {
    [self setNeedsDisplay];
}

#pragma mark - Utilities

- (NSDictionary *)jsq_placeholderTextAttributes {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = self.textAlignment;

    return @{ NSFontAttributeName : self.font,
              NSForegroundColorAttributeName : self.placeHolderTextColor,
              NSParagraphStyleAttributeName : paragraphStyle };
}

#pragma mark - UIMenuController

- (BOOL)isCustomMenuItemSelector:(SEL)aSelector {
    for (UIMenuItem *item in self.customMenuItems) {
        if (item.action == aSelector) {
            return YES;
        }
    }
    for (UIMenuItem *item in self.customTextStyleOptions) {
        if (item.action == aSelector) {
            return YES;
        }
    }
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    
    if ([super methodSignatureForSelector:aSelector]) {
        return [super methodSignatureForSelector:aSelector];
    }
    return [self.customTarget methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    
    if ([self isCustomMenuItemSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.customTarget];
    } else {
        [super forwardInvocation: anInvocation];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    if (!self.selectedTextRange.empty) {
        
        if ([self isTextStyleOptionsMenuItemSelected]) {
            [UIMenuController.sharedMenuController setMenuItems:self.customTextStyleOptions];
        }
        
        BOOL isActionTextStyleOptions = action == @selector(_showTextStyleOptions:);
        BOOL areCustomTextStyleOptionsDefined = self.customTextStyleOptions.count > 0;
        BOOL shouldDisplayTextStyleOptionsItem = isActionTextStyleOptions && areCustomTextStyleOptionsDefined && ![self textStyleOptionsMenuItemContainsCustomItems];
        if (shouldDisplayTextStyleOptionsItem) {
            return YES;
        }
        
        if (UIMenuController.sharedMenuController.menuItems == nil) {
            [UIMenuController.sharedMenuController setMenuItems:self.customMenuItems];
        }
        
        if ([self isCustomMenuItemSelector:action]) {
            return YES;
        }
    } else {
        [UIMenuController.sharedMenuController setMenuItems:nil];
    }
    
    return [super canPerformAction:action withSender:sender];
}

-(BOOL)isTextStyleOptionsMenuItemSelected {
    NSArray<NSString*> *textStyleOptionsSelectors = @[@"toggleBoldface:", @"toggleItalics:", @"toggleUnderline:"];
    for (UIMenuItem *menuItem in UIMenuController.sharedMenuController.menuItems) {
        if ([textStyleOptionsSelectors containsObject:NSStringFromSelector(menuItem.action)]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)textStyleOptionsMenuItemContainsCustomItems {
    for (UIMenuItem *menuItem in UIMenuController.sharedMenuController.menuItems) {
        if ([self.customTextStyleOptions containsObject:menuItem]) {
            return YES;
        }
    }
    return NO;
}

- (void)setCustomMenuItemsForCurrentSelectedText:(NSArray<UIMenuItem *> *)menuItems actionsTarget:(id)target {
    self.customMenuItems = menuItems;
    self.customTarget = target;
    [UIMenuController.sharedMenuController update];
}

- (void)setCustomMenuItemsForTextStyleOptions:(NSArray<UIMenuItem *> *)customTextStyleOptions actionsTarget:(id)target {
    self.customTextStyleOptions = customTextStyleOptions;
    self.customTarget = target;
}


@end
