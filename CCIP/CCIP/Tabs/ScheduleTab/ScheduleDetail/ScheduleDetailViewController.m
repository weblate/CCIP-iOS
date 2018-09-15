//
//  ScheduleDetailViewController.m
//  CCIP
//
//  Created by 腹黒い茶 on 2017/07/21.
//  Copyright © 2017年 CPRTeam. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import "UITableView+FDTemplateLayoutCell.h"
#import "AppDelegate.h"
#import "ScheduleDetailViewController.h"
#import "UIColor+addition.h"
#import "UIView+addition.h"
#import "WebServiceEndPoint.h"
#import "ScheduleAbstractViewCell.h"
#import "ScheduleSpeakerInfoViewCell.h"

#define ABSTRACT_CELL       (@"ScheduleAbstract")
#define SPEAKERINFO_CELL    (@"ScheduleSpeakerInfo")

@interface ScheduleDetailViewController ()

@property (strong, nonatomic) NSMutableArray *identifiers;
@property (strong, nonatomic) NSDictionary *detailData;
@property (strong, nonatomic) NSArray *speakers;

@end

@implementation ScheduleDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    SEND_FIB(@"ScheduleDetailViewController");
    
    self.identifiers = [NSMutableArray new];
    [self.tvContent setSeparatorColor:[UIColor clearColor]];
    self.speakers = @[];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    NSDictionary *data = self.detailData;
    ////
    [self.identifiers addObject:ABSTRACT_CELL];
    
    for (int i = 0; i < [[data objectForKey:@"speakers"] count]; i++) {
        [self.identifiers addObject:SPEAKERINFO_CELL];
    }
    ////
    self.speakers = [data objectForKey:@"speakers"];
    [self.vwHeader registerClass:[FSPagerViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self.vwHeader setDelegate:self];
    [self.vwHeader setDataSource:self];
    [self.vwHeader setIsInfinite:YES];
    if ([self.speakers count] > 1) {
        [self.vwHeader setAutomaticSlidingInterval:3.0];
    }
    UIView *fspager = [self.vwHeader.subviews lastObject];
    [self.vwHeader sendSubviewToBack:fspager];
    [fspager setUserInteractionEnabled:NO];
    NSDateFormatter *formatter_full = nil;
    formatter_full = [NSDateFormatter new];
    [formatter_full setDateFormat:[AppDelegate AppConfig:@"DateTimeFormat"]];
    NSDateFormatter *formatter_date = nil;
    formatter_date = [NSDateFormatter new];
    [formatter_date setDateFormat:[AppDelegate AppConfig:@"DisplayTimeFormat"]];
    [formatter_date setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Taipei"]];
    NSDate *startTime = [formatter_full dateFromString:[data objectForKey:@"start"]];
    NSDate *endTime = [formatter_full dateFromString:[data objectForKey:@"end"]];
    NSString *startTimeString = [formatter_date stringFromDate:startTime];
    NSString *endTimeString = [formatter_date stringFromDate:endTime];
    NSString *timeRange = [NSString stringWithFormat:@"%@ - %@", startTimeString, endTimeString];
    NSDictionary *currentLangObject = [data objectForKey:[AppDelegate shortLangUI]];
    [self.lbTitle setText:[currentLangObject objectForKey:@"subject"]];
    [self.lbSpeakerName setText:[[data objectForKey:@"speaker"] objectForKey:@"name"]];
    [self.lbRoomText setText:[data objectForKey:@"room"]];
    [self.lbLangText setText:[data objectForKey:@"lang"]];
    [self.lbTimeText setText:timeRange];
    
    [self.vwHeader setGradientColor:[AppDelegate AppConfigColor:@"ScheduleTitleLeftColor"]
                                 To:[AppDelegate AppConfigColor:@"ScheduleTitleRightColor"]
                         StartPoint:CGPointMake(1, .5)
                            ToPoint:CGPointMake(-.4, .5)];
    
    // following constraint for fix the storyboard autolayout broken the navigation bar alignment
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.vwHeader
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0]];

    NSArray *lbsHeader = @[
                           self.lbSpeaker,
                           self.lbSpeakerName,
                           self.lbTitle
                           ];
    NSArray *lbsMeta = @[
                         self.lbRoom,
                         self.lbRoomText,
                         self.lbLang,
                         self.lbLangText,
                         self.lbTime,
                         self.lbTimeText
                         ];
    for (UILabel *lb in lbsHeader) {
        [lb setTextColor:[AppDelegate AppConfigColor:@"ScheduleDetailHeaderTextColor"]];
        [lb.layer setShadowColor:[[UIColor grayColor] CGColor]];
        [lb.layer setShadowRadius:3.0f];
        [lb.layer setShadowOpacity:.8f];
        [lb.layer setShadowOffset:CGSizeZero];
        [lb.layer setMasksToBounds:NO];
    }
    for (UILabel *lb in lbsMeta) {
        [lb setTextColor:[AppDelegate AppConfigColor:@"ScheduleMetaHeaderTextColor"]];
        [lb.layer setShadowColor:[[UIColor grayColor] CGColor]];
        [lb.layer setShadowRadius:3.0f];
        [lb.layer setShadowOpacity:.8f];
        [lb.layer setShadowOffset:CGSizeZero];
        [lb.layer setMasksToBounds:NO];
    }
}

#pragma mark - FSPagerView

- (NSInteger)numberOfItemsInPagerView:(FSPagerView *)pagerView {
    return [self.speakers count];
}

- (FSPagerViewCell *)pagerView:(FSPagerView *)pagerView cellForItemAtIndex:(NSInteger)index {
    UIImage *defaultIcon = ASSETS_IMAGE(@"PassAssets", @"StaffIconDefault");
    NSDictionary *speaker = [self.speakers objectAtIndex:index];
    NSString *avatar = [speaker objectForKey:@"avatar"];
    NSString *speakerPhoto = [avatar stringByReplacingOccurrencesOfString:@"http:"
                                                               withString:@"https:"];
    NSURL *speakerPhotoURL = [NSURL URLWithString:speakerPhoto];
    NSLog(@"Loading Speaker Photo -> %@ (Parsed as %@)", speakerPhoto, speakerPhotoURL);
    FSPagerViewCell *cell = [pagerView dequeueReusableCellWithReuseIdentifier:@"cell" atIndex:index];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[speaker objectForKey:@"avatar"]]
                      placeholderImage:defaultIcon
                               options:SDWebImageRefreshCached];
//    [cell.textLabel setText:[[speaker objectForKey:[AppDelegate shortLangUI]] objectForKey:@"name"]];
    [self.lbSpeakerName setText:[[speaker objectForKey:[AppDelegate shortLangUI]] objectForKey:@"name"]];
    return cell;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.identifiers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self.identifiers objectAtIndex:indexPath.row]];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView fd_heightForCellWithIdentifier:[self.identifiers objectAtIndex:indexPath.row] configuration:^(id cell) {
        [self configureCell:cell atIndexPath:indexPath];
    }];
}

- (void)setTextFit:(UILabel *)label WithContent:(NSString *)content {
    NSMutableString *fakeContent = [NSMutableString stringWithString:content];
    [fakeContent appendString:@"\n　\n　\n　\n"];
    [label setText:fakeContent];
    [label sizeToFit];
    UITableViewCell *cell = (UITableViewCell *)label.superview;
    [cell setFd_enforceFrameLayout:YES];
    [label setText:content];
    [label sizeToFit];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    [cell setFd_enforceFrameLayout:NO]; // Enable to use "-sizeThatFits:"
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setClipsToBounds:NO];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell.layer setZPosition:indexPath.row];
    UIView *vwContent = [cell performSelector:@selector(vwContent)];
    [vwContent.layer setCornerRadius:5.0f];
    [vwContent.layer setShadowRadius:50.0f];
    [vwContent.layer setShadowOffset:CGSizeMake(0, 50)];
    [vwContent.layer setShadowColor:[[UIColor blackColor] CGColor]];
    [vwContent.layer setShadowOpacity:0.1f];
    [vwContent.layer setMasksToBounds:NO];
    NSMutableArray *cells = [NSMutableArray new];
    
    [cells addObject:^{
        ScheduleAbstractViewCell *abstractCell = (ScheduleAbstractViewCell *)cell;
        NSDictionary *currentLangObject = [self.detailData objectForKey:[AppDelegate shortLangUI]];
        NSString *summary = [NSString stringWithFormat:@"%@\n", [currentLangObject objectForKey:@"summary"]];
        NSLog(@"Set summary: %@", summary);
        [self setTextFit:abstractCell.lbAbstractContent
             WithContent:summary];
        [abstractCell setFd_enforceFrameLayout: YES]; // enable (CGSize)sizeThatFits:(CGSize)size
        [abstractCell.lbAbstractText setTextColor:[AppDelegate AppConfigColor:@"CardTextColor"]];
    }];
    
    for (NSDictionary *speaker in [self.detailData objectForKey:@"speakers"]) {
        [cells addObject:^{
            ScheduleSpeakerInfoViewCell *speakerInfoCell = (ScheduleSpeakerInfoViewCell *)cell;
            
            [self setTextFit:speakerInfoCell.lbSpeakerInfoTitle
                 WithContent:[[speaker objectForKey:[AppDelegate shortLangUI]] objectForKey:@"name"]];
            [speakerInfoCell.lbSpeakerInfoTitle setTextColor:[AppDelegate AppConfigColor:@"CardTextColor"]];
            
            NSString *bio = [NSString stringWithFormat:@"%@\n", [[speaker objectForKey:[AppDelegate shortLangUI]] objectForKey:@"bio"]];
            NSLog(@"Set bio: %@", bio);
            [self setTextFit:speakerInfoCell.lbSpeakerInfoContent
                 WithContent:bio];
        }];
    }
    
    @try {
        void(^block)(void) = [cells objectAtIndex:indexPath.row];
        block();
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

- (void)setDetailData:(NSDictionary *)data {
    _detailData = data;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
