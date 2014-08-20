//
//  SCKChatViewController.m
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SCKChatViewController.h"
#import "UITextView+SCKHelpers.h"

@interface SCKChatViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
{
    CGFloat minYOffset;
    UIGestureRecognizer *dismissingGesture;
    
    CGFloat textContentHeight;
}

@property (nonatomic, strong) NSLayoutConstraint *tableViewHC;
@property (nonatomic, strong) NSLayoutConstraint *containerViewHC;
@property (nonatomic, strong) NSLayoutConstraint *typeIndicatorViewHC;
@property (nonatomic, strong) NSLayoutConstraint *keyboardHC;

@end

@implementation SCKChatViewController
@synthesize tableView = _tableView;
@synthesize typeIndicatorView = _typeIndicatorView;
@synthesize textContainerView = _textContainerView;


#pragma mark - Initializer

- (instancetype)init
{
    if (self = [super init])
    {
        self.allowElasticity = YES;
        
        [self.view addSubview:self.tableView];
        [self.view addSubview:self.typeIndicatorView];
        [self.view addSubview:self.textContainerView];

        [self setupViewConstraints];
        
        [self registerNotifications];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // We save the minimum offset of the tableView
    minYOffset = self.tableView.contentOffset.y;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


#pragma mark - Getters

- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [UITableView new];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.scrollsToTop = YES;
        _tableView.dataSource = self;
        _tableView.delegate = self;

        dismissingGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
        dismissingGesture.delegate = self;
        [_tableView addGestureRecognizer:dismissingGesture];
    }
    return _tableView;
}

- (SCKTextContainerView *)textContainerView
{
    if (!_textContainerView)
    {
        _textContainerView = [SCKTextContainerView new];
        _textContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        textContentHeight = self.textView.contentSize.height;
    }
    return _textContainerView;
}

- (SCKTypeIndicatorView *)typeIndicatorView
{
    if (!_typeIndicatorView)
    {
        _typeIndicatorView = [[SCKTypeIndicatorView alloc] init];
        _typeIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        _typeIndicatorView.layer.shadowOpacity = 0.8;
        _typeIndicatorView.layer.shadowColor = [UIColor whiteColor].CGColor;
        _typeIndicatorView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    }
    return _typeIndicatorView;
}

- (SCKTextView *)textView
{
    return self.textContainerView.textView;
}

- (UIButton *)leftButton
{
    return self.textContainerView.leftButton;
}

- (UIButton *)rightButton
{
    return self.textContainerView.rightButton;
}

- (CGFloat)damping
{
    return self.allowElasticity ? 0.7 : 1.0;
}

- (CGFloat)velocity
{
    return self.allowElasticity ? 0.7 : 1.0;
}


#pragma mark - Setters



#pragma mark - Actions

- (void)scrollToBottomAnimated:(BOOL)animated
{
//    if ([self.tableView numberOfSections] == 0) {
//        return;
//    }
//    
//    NSInteger items = [self.tableView numberOfRowsInSection:0];
//    
//    if (items > 0) {
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:items - 1 inSection:0]
//                              atScrollPosition:UITableViewScrollPositionTop
//                                      animated:animated];
//    }
}

- (void)presentKeyboard
{
    if (![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

- (void)dismissKeyboard
{
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}


#pragma mark - Notification Events

- (void)willShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    endFrame = adjustEndFrame(endFrame, self.interfaceOrientation);
    
    if (!isKeyboardFrameValid(endFrame)) return;

    // Checks if it's showing or hidding the keyboard
    BOOL show = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    
    CGRect inputFrame = self.textContainerView.frame;
    inputFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(inputFrame);
    
    self.tableViewHC.constant = CGRectGetMinY(inputFrame) - self.typeIndicatorViewHC.constant;
    self.keyboardHC.constant = show ? endFrame.size.height : 0.0;
    
    CGFloat delta = CGRectGetHeight(endFrame);
    CGFloat offsetY = self.tableView.contentOffset.y+(show ? delta : -delta);
    
    CGFloat currentYOffset = self.tableView.contentOffset.y;
    CGFloat maxYOffset = self.tableView.contentSize.height-(CGRectGetHeight(self.view.frame)-CGRectGetHeight(inputFrame));
    
    BOOL scroll = ((!show && offsetY != currentYOffset && offsetY > (minYOffset-delta) && offsetY < (maxYOffset-delta+minYOffset)) || show);
    
    [UIView animateWithDuration:duration*3
                          delay:0.0
                        options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         [self.view layoutIfNeeded];
                         
                         if (scroll) {
                             self.tableView.contentOffset = CGPointMake(0, offsetY);
                         }
                     }
                     completion:NULL];
}

- (void)didShowOrHideKeyboard:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    endFrame = adjustEndFrame(endFrame, self.interfaceOrientation);
    
    if (!isKeyboardFrameValid(endFrame)) return;

    CGRect inputFrame = self.textContainerView.frame;
    inputFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(inputFrame);
    
    self.tableViewHC.constant = CGRectGetMinY(inputFrame);
    
    if (self.typeIndicatorView.isVisible) {
        self.tableViewHC.constant -= self.typeIndicatorViewHC.constant;
    }
    
    [self.view layoutIfNeeded];
}

- (void)didChangeKeyboardFrame:(NSNotification *)notification
{
    CGRect endFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect inputFrame = self.textContainerView.frame;
    
    inputFrame.origin.y  = CGRectGetMinY(endFrame)-CGRectGetHeight(inputFrame);

    self.tableViewHC.constant = CGRectGetMinY(inputFrame) - self.typeIndicatorViewHC.constant;
    self.keyboardHC.constant = CGRectGetHeight(self.view.frame)-endFrame.origin.y;
    
    [self.view layoutIfNeeded];
}

- (void)didChangeTextView:(NSNotification *)notification
{
    SCKTextView *textView = (SCKTextView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![textView isEqual:self.textView]) {
        NSLog(@"Not the expected textView, return");
        return;
    }
    
    CGSize textContentSize = textView.contentSize;
    
    // If the content size didn't change, return.
    if (textContentSize.height == textContentHeight) {
        NSLog(@"The content size didn't change, return");
        return;
    }

    if (textContentSize.height != textContentHeight)
    {
        CGFloat delta = textContentSize.height-textContentHeight;
        CGFloat containerNewHeight = 0;
        
        if (textView.numberOfLines <= textView.maxNumberOfLines) {
            containerNewHeight = textContentHeight+delta+(kTextViewVerticalPadding*2.0);
        }
        else if (self.containerViewHC.constant < self.textContainerView.maxHeight) {
            containerNewHeight = self.textContainerView.maxHeight;
        }
        
        if (containerNewHeight < self.textContainerView.minHeight) {
            NSLog(@"The containerNewHeight smaller than min height (%f): return", containerNewHeight);
            return;
        }
        
        if (containerNewHeight != self.containerViewHC.constant)
        {
            CGFloat offsetDelta = roundf(self.containerViewHC.constant-containerNewHeight);
            
            self.containerViewHC.constant = containerNewHeight;
            self.tableViewHC.constant = (self.keyboardHC.constant-containerNewHeight)-self.typeIndicatorViewHC.constant;
            
            CGFloat offsetY = self.tableView.contentOffset.y-offsetDelta;
            
            [UIView animateWithDuration:0.5
                                  delay:0.0
                 usingSpringWithDamping:[self damping]
                  initialSpringVelocity:[self velocity]
                                options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                             animations:^{
                                 [self.view layoutIfNeeded];
                                 [self.tableView setContentOffset:CGPointMake(0.0, offsetY)];
                                 
                                 if (self.textView.selectedRange.length == 0) {
                                     [self.textView scrollRangeToBottom];
                                 }
                             }
                             completion:NULL];
        }
        else {
            NSLog(@"The self.containerViewHC didn't change (%f): return", containerNewHeight);
            return;
        }
    }
}

- (void)willShowOrHideTypeIndicatorView:(NSNotification *)notification
{
    SCKTypeIndicatorView *indicatorView = (SCKTypeIndicatorView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![indicatorView isEqual:self.typeIndicatorView]) {
        NSLog(@"Not the expected indicatorView, return");
        return;
    }
    
    self.typeIndicatorViewHC.constant = indicatorView.isVisible ? indicatorView.height : 0.0;
    self.tableViewHC.constant -= self.typeIndicatorViewHC.constant;

    [UIView animateWithDuration:0.2
                          delay:0.0
         usingSpringWithDamping:[self damping]
          initialSpringVelocity:[self velocity]
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         [self.view layoutIfNeeded];
                         
                         CGFloat offsetDelta = indicatorView.isVisible ? indicatorView.height : -indicatorView.height;
                         CGFloat offsetY = self.tableView.contentOffset.y+offsetDelta;
                         self.tableView.contentOffset = CGPointMake(0, offsetY);
                     }
                     completion:NULL];
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([dismissingGesture isEqual:gestureRecognizer]) {
        return [self.textContainerView.textView isFirstResponder];
    }
    
    return YES;
}


#pragma mark - NSNotificationCenter register/unregister

- (void)registerNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeKeyboardFrame:) name:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didShowOrHideKeyboard:) name:UIKeyboardDidHideNotification object:nil];
    
    // TextView notifications
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:SCKTextViewContentSizeDidChangeNotification object:nil];
    
    // TypeIndicator notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideTypeIndicatorView:) name:SCKTypeIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowOrHideTypeIndicatorView:) name:SCKTypeIndicatorViewWillHideNotification object:nil];
}

- (void)unregisterNotifications
{
    // Keyboard notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
    // TextView notifications
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTextViewContentSizeDidChangeNotification object:nil];
    
    // TextView notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTypeIndicatorViewWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCKTypeIndicatorViewWillHideNotification object:nil];
}


#pragma mark - View Auto-Layout

- (void)setupViewConstraints
{
    // Removes all constraints
    [self.view removeConstraints:self.view.constraints];
    
    NSDictionary *views = @{@"tableView": self.tableView,
                            @"textContainerView": self.textContainerView,
                            @"typeIndicatorView": self.typeIndicatorView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView(0@250)][typeIndicatorView(0)][textContainerView(0@750)]-0-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[textContainerView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[typeIndicatorView]|" options:0 metrics:nil views:views]];
    
    NSArray *heightConstraints = [self constraintsForAttribute:NSLayoutAttributeHeight];
    NSArray *bottomConstraints = [self constraintsForAttribute:NSLayoutAttributeBottom];
    
    self.tableViewHC = heightConstraints[0];
    self.typeIndicatorViewHC = heightConstraints[1];
    self.containerViewHC = heightConstraints[2];
    
    self.keyboardHC = bottomConstraints[0];
    
    self.containerViewHC.constant = self.textContainerView.minHeight;
}

- (NSArray *)constraintsForAttribute:(NSLayoutAttribute)attribute
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", attribute];
    return [self.view.constraints filteredArrayUsingPredicate:predicate];
}


#pragma mark - Convenience Methods

CGRect adjustEndFrame(CGRect endFrame, UIInterfaceOrientation orientation) {
    
    // Inverts the end rect for landscape orientation
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        endFrame = CGRectMake(0.0, endFrame.origin.x, endFrame.size.height, endFrame.size.width);
    }
    
    return endFrame;
}

BOOL isKeyboardFrameValid(CGRect frame) {
    if ((frame.origin.y > CGRectGetHeight([UIScreen mainScreen].bounds)) ||
        (frame.size.height < 1) || (frame.size.width < 1) || (frame.origin.y < 0)) {
        return NO;
    }
    return YES;
}


#pragma mark - View Auto-Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.view layoutIfNeeded];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}


#pragma mark - View lifeterm

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
    [self unregisterNotifications];
}

@end
