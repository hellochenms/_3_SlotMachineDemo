//
//  RootViewController.m
//  SlotMachineDemo
//
//  Created by Chen Meisong on 13-12-25.
//  Copyright (c) 2013年 Chen Meisong. All rights reserved.
//

#import "RootViewController.h"
#import "ZCSlotMachine.h"

#define RVC_SLOT_COUNT 4

@interface RootViewController ()<ZCSlotMachineDataSource, ZCSlotMachineDelegate, UIPickerViewDataSource, UIPickerViewDelegate>{
    ZCSlotMachine   *_slotMachine;
    UIButton        *_startButton;
    NSArray         *_titles;
    NSArray         *_icons;
    NSMutableArray  *_winResults;
}
@end

@implementation RootViewController

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        _titles = @[@"快装", @"天气预报", @"App123", @"快游"];
        _icons = @[[UIImage imageNamed:@"kuaiapp"],
                        [UIImage imageNamed:@"weather"],
                        [UIImage imageNamed:@"app123"],
                        [UIImage imageNamed:@"kuaigame"]];
        _winResults = [NSMutableArray arrayWithArray:@[@0, @0, @0, @0]];
    }
    return self;
}

- (void)loadView{
    self.view = [UIView new];
    
    CGRect frame = [UIScreen mainScreen].bounds;
    
    _slotMachine = [[ZCSlotMachine alloc] initWithFrame:CGRectMake(10, 20, CGRectGetWidth(frame) - 20, 260)];
    _slotMachine.backgroundImage = [UIImage imageNamed:@"common_bg"];
    _slotMachine.coverImage = [self rectImageForColor:[[UIColor blackColor] colorWithAlphaComponent:0.4]];
    _slotMachine.dataSource = self;
    _slotMachine.delegate = self;
    [self.view addSubview:_slotMachine];
    
    _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _startButton.frame = CGRectMake(60, CGRectGetMaxY(_slotMachine.frame) + 40, 200, 40);
    [_startButton setBackgroundImage:[UIImage imageNamed:@"button_bg"] forState:UIControlStateNormal];
    [_startButton setTitle:@"摇奖" forState:UIControlStateNormal];
    [_startButton addTarget:self action:@selector(onTapStart) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_startButton];
    
    UIButton *sendResponseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendResponseButton.frame = CGRectMake(60, CGRectGetMaxY(_startButton.frame) + 10, 200, 40);
    [sendResponseButton setBackgroundImage:[UIImage imageNamed:@"button_bg"] forState:UIControlStateNormal];
    [sendResponseButton setTitle:@"服务端发送响应" forState:UIControlStateNormal];
    [sendResponseButton addTarget:self action:@selector(onTapSendResponse) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendResponseButton];
    
    UIPickerView *pickView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(sendResponseButton.frame), 320, 200)];
    pickView.dataSource = self;
    pickView.delegate = self;
    [self.view addSubview:pickView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 
- (void)onTapStart{
    _slotMachine.slotResults = @[@0, @1, @2, @3];
    [_slotMachine startSliding];
}

#pragma mark - ZCSlotMachineDataSource
- (NSUInteger)numberOfSlotsInSlotMachine:(ZCSlotMachine *)slotMachine{
    return RVC_SLOT_COUNT;
}
- (NSArray *)iconsForSlotsInSlotMachine:(ZCSlotMachine *)slotMachine{
    return _icons;
}
- (CGFloat)slotWidthInSlotMachine:(ZCSlotMachine *)slotMachine {
    return 72;
}

- (CGFloat)slotSpacingInSlotMachine:(ZCSlotMachine *)slotMachine {
    return 4;
}
#pragma mark - ZCSlotMachineDelegate
- (void)slotMachineWillStartSliding:(ZCSlotMachine *)slotMachine{
    _startButton.enabled = NO;
}
- (void)slotMachineDidEndSliding:(ZCSlotMachine *)slotMachine{
    _startButton.enabled = YES;
    NSArray *results = [_slotMachine realResults];
    if (!results) {
        results = _slotMachine.slotResults;
    }
    if ([self isWinForResults:results]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"恭喜您中奖了！"
                                                               delegate:nil
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
}

#pragma mark - 
- (void)onTapSendResponse{
    [_slotMachine trySetRealResults:_winResults];
}

#pragma mark - 
- (UIImage*)rectImageForColor:(UIColor*)color{
    if (!color) {
        return nil;
    }
    CGRect rect = CGRectMake(0, 0, 300, 80);
    UIGraphicsBeginImageContext(rect.size);
    [color set];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return RVC_SLOT_COUNT;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return _titles.count;
}
#pragma mark - UIPickerViewDelegate
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return 30;
}
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:14];
    label.text = _titles[row];
    
    return label;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    [_winResults replaceObjectAtIndex:component withObject:@(row)];
}

#pragma mark -
- (BOOL)isWinForResults:(NSArray*)results{
    if (!results || results.count != RVC_SLOT_COUNT) {
        return NO;
    }
    
    BOOL isWin = YES;
    int item0 = [[results objectAtIndex:0] intValue];
    int item = -1;
    for (int i = 1; i < results.count; i++) {
        item = [[results objectAtIndex:i] intValue];
        if (item != item0) {
            isWin = NO;
            break;
        }
    }
    
    return isWin;
}

@end
