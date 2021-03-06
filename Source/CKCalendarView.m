//
// Copyright (c) 2012 Jason Kozemczak
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//


@import QuartzCore;
@import CoreGraphics;
#import "CKCalendarView.h"

#define DEFAULT_CELL_WIDTH 43
#define DEFAULT_CELL_BORDER_WIDTH 2

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@class CALayer;
@class CAGradientLayer;

@interface GradientView : UIView

@property(nonatomic, strong, readonly) CAGradientLayer *gradientLayer;
- (void)setColors:(NSArray *)colors;

@end

@implementation GradientView

- (id)init {
    return [self initWithFrame:CGRectZero];
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (CAGradientLayer *)gradientLayer {
    return (CAGradientLayer *)self.layer;
}

- (void)setColors:(NSArray *)colors {
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(__bridge id)color.CGColor];
    }
    self.gradientLayer.colors = cgColors;
}

@end


@interface DateButton : UIButton

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSCalendar *calendar;

@property (nonatomic, assign) BOOL marked;
@property (nonatomic, strong) UILabel *markLabel;

@end

@implementation DateButton

@synthesize date = _date;
@synthesize calendar = _calendar;

@synthesize marked = _marked;
@synthesize markLabel = _markLabel;

- (void)setDate:(NSDate *)date {
    _date = date;
    NSDateComponents *comps = [self.calendar components:NSDayCalendarUnit|NSMonthCalendarUnit fromDate:date];
    [self setTitle:[NSString stringWithFormat:@"%ld", (long)comps.day] forState:UIControlStateNormal];
}

- (void)setMarked:(BOOL)marked
{
    _marked = marked;
    if(_marked && self.markLabel == nil) {
        self.markLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.markLabel.font = self.titleLabel.font;
        self.markLabel.textColor = self.currentTitleColor;
        self.markLabel.backgroundColor = [UIColor clearColor];
        self.markLabel.text = @"•";
        [self.markLabel sizeToFit];
        [self insertSubview:self.markLabel aboveSubview:self.titleLabel];
        [self setNeedsLayout];
		
    } else if(!_marked && self.markLabel != nil){
        
        [self.markLabel removeFromSuperview];
        self.markLabel = nil;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if(self.markLabel != nil) {
        self.markLabel.center = CGPointMake(self.titleLabel.center.x, self.titleLabel.center.y + 16);
    }
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    self.markLabel.textColor = self.currentTitleColor;
    return [super titleRectForContentRect:contentRect];
}

@end


@interface CKCalendarView ()

@property(nonatomic, strong) UIView *highlight;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIButton *prevButton;
@property(nonatomic, strong) UIButton *nextButton;
@property(nonatomic, strong) UIView *calendarContainer;
@property(nonatomic, strong) GradientView *daysHeader;
@property(nonatomic, strong) NSArray *dayOfWeekLabels;
@property(nonatomic, strong) NSMutableArray *dateButtons;
@property(nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) NSDate *monthShowing;
@property (nonatomic, strong) NSCalendar *calendar;
@property(nonatomic, assign) CGFloat cellWidth;


@end

@implementation CKCalendarView

@synthesize highlight = _highlight;
@synthesize titleLabel = _titleLabel;
@synthesize prevButton = _prevButton;
@synthesize nextButton = _nextButton;
@synthesize calendarContainer = _calendarContainer;
@synthesize daysHeader = _daysHeader;
@synthesize dayOfWeekLabels = _dayOfWeekLabels;
@synthesize dateButtons = _dateButtons;

@synthesize monthShowing = _monthShowing;
@synthesize calendar = _calendar;
@synthesize dateFormatter = _dateFormatter;

@synthesize selectedDate = _selectedDate;
@synthesize delegate = _delegate;

@synthesize dateTextColor = _dateTextColor;
@synthesize selectedDateTextColor = _selectedDateTextColor;
@synthesize selectedDateBackgroundColor = _selectedDateBackgroundColor;
@synthesize selectedDateBorderColor = _selectedDateBorderColor;
@synthesize currentDateTextColor = _currentDateTextColor;
@synthesize currentDateBackgroundColor = _currentDateBackgroundColor;
@synthesize nonCurrentMonthDateTextColor = _nonCurrentMonthDateTextColor;
@synthesize disabledDateTextColor = _disabledDateTextColor;
@synthesize disabledDateBackgroundColor = _disabledDateBackgroundColor;
@synthesize calendarMargin = _calendarMargin;
@synthesize cornerRadius = _cornerRadius;
@synthesize calendarCornerRadius = _calendarCornerRadius;
@synthesize highlightVisible = _highlightVisible;
@synthesize topHeight = _topHeight;
@synthesize daysHeaderHeight = _daysHeaderHeight;
@synthesize markedDates = _markedDates;
@synthesize cellWidth = _cellWidth;

@synthesize calendarStartDay = _calendarStartDay;
@synthesize minimumDate = _minimumDate;
@synthesize maximumDate = _maximumDate;
@synthesize shouldFillCalendar = _shouldFillCalendar;


- (id)init {
    return [self initWithStartDay:startSunday];
}

- (id)initWithStartDay:(startDay)firstDay {
    return [self initWithStartDay:firstDay frame:CGRectMake(0, 0, 320, 320)];
}

- (void)internalInit:(startDay)firstDay {
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [self.calendar setLocale:[NSLocale currentLocale]];
	
    self.cellWidth = DEFAULT_CELL_WIDTH;
	self.cellBorderWidth = DEFAULT_CELL_BORDER_WIDTH;
	
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"LLLL yyyy" options:0 locale:[NSLocale currentLocale]];
	
    self.calendarStartDay = firstDay;
    self.shouldFillCalendar = NO;
    _highlightVisible = YES;
	
    self.layer.cornerRadius = self.cornerRadius;
	
    UIView *highlight = [[UIView alloc] initWithFrame:CGRectZero];
    highlight.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    highlight.layer.cornerRadius = self.cornerRadius;
    highlight.hidden = !_highlightVisible;
    [self addSubview:highlight];
    self.highlight = highlight;
	
    // SET UP THE HEADER
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;
	
    UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [prevButton setImage:[UIImage imageNamed:@"calendar-header-left-arrow.png"] forState:UIControlStateNormal];
    prevButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
    [prevButton addTarget:self action:@selector(moveCalendarToPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:prevButton];
    self.prevButton = prevButton;
	
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [nextButton setImage:[UIImage imageNamed:@"calendar-header-right-arrow.png"] forState:UIControlStateNormal];
    nextButton.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
    [nextButton addTarget:self action:@selector(moveCalendarToNextMonth) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:nextButton];
    self.nextButton = nextButton;
	
    // THE CALENDAR ITSELF
    UIView *calendarContainer = [[UIView alloc] initWithFrame:CGRectZero];
    calendarContainer.layer.borderWidth = 1.0f;
    calendarContainer.layer.borderColor = [UIColor blackColor].CGColor;
    calendarContainer.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    calendarContainer.layer.cornerRadius = self.calendarCornerRadius;
    calendarContainer.clipsToBounds = YES;
    [self addSubview:calendarContainer];
    self.calendarContainer = calendarContainer;
	
    GradientView *daysHeader = [[GradientView alloc] initWithFrame:CGRectZero];
    daysHeader.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.calendarContainer addSubview:daysHeader];
    self.daysHeader = daysHeader;
	
    NSMutableArray *labels = [NSMutableArray array];
    for (NSString *day in [self getDaysOfTheWeek]) {
        UILabel *dayOfWeekLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        dayOfWeekLabel.text = [day uppercaseString];
        dayOfWeekLabel.textAlignment = NSTextAlignmentCenter;
        dayOfWeekLabel.backgroundColor = [UIColor clearColor];
        dayOfWeekLabel.shadowColor = [UIColor whiteColor];
        dayOfWeekLabel.shadowOffset = CGSizeMake(0, 1);
        [labels addObject:dayOfWeekLabel];
        [self.calendarContainer addSubview:dayOfWeekLabel];
    }
    self.dayOfWeekLabels = labels;
	
    // at most we'll need 42 buttons, so let's just bite the bullet and make them now...
    NSMutableArray *dateButtons = [NSMutableArray array];
    for (NSInteger i = 1; i <= 42; i++) {
        DateButton *dateButton = [DateButton buttonWithType:UIButtonTypeCustom];
        dateButton.calendar = self.calendar;
        [dateButton addTarget:self action:@selector(dateButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [dateButtons addObject:dateButton];
    }
    self.dateButtons = dateButtons;
	
    // initialize the thing
    self.monthShowing = [NSDate date];
    [self setDefaultStyle];
    
    [self layoutSubviews]; // TODO: this is a hack to get the first month to show properly
}

- (id)initWithStartDay:(startDay)firstDay frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self internalInit:firstDay];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [self initWithStartDay:startSunday frame:frame];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalInit:startSunday];
    }
	
    return self;
}

- (CGFloat)measuredHeight
{
    return [self containerHeight] + self.calendarMargin + self.topHeight;
}

- (CGFloat)containerHeight
{
    return ([self numberOfWeeksInMonthContainingDate:self.monthShowing] * (self.cellWidth + self.cellBorderWidth) + self.daysHeaderHeight);
}

- (CGFloat)containerWidth
{
    return self.bounds.size.width - (self.calendarMargin * 2);
}

- (NSDate *)firstVisibleDate
{
    NSDate *date = [self firstDayOfMonthContainingDate:self.monthShowing];
    if (self.shouldFillCalendar) {
        while ([self placeInWeekForDate:date] != 0) {
            date = [self previousDay:date];
        }
    }
    return date;
}

- (NSDate *)lastVisibleDate
{
    NSDate *endDate = [self firstDayOfNextMonthContainingDate:self.monthShowing];
    if (self.shouldFillCalendar) {
        while ([self placeInWeekForDate:endDate] != 0) {
            endDate = [self nextDay:endDate];
        }
    }
    return endDate;
}

- (void) setCellBorderWidth:(CGFloat)cellBorderWidth
{
	_cellBorderWidth = cellBorderWidth;
	
	[self setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
	
    CGFloat containerWidth = [self containerWidth];
    self.cellWidth = (containerWidth / 7.0) - self.cellBorderWidth;
	
    CGFloat containerHeight = [self containerHeight];
	
	
    CGRect newFrame = self.frame;
    newFrame.size.height = [self measuredHeight];
    self.frame = newFrame;
	
    self.highlight.frame = CGRectMake(1, 1, self.bounds.size.width - 2, 1);
	
    self.titleLabel.frame = CGRectMake(0, 0, self.bounds.size.width, self.topHeight);
    CGFloat buttonMargin = (self.topHeight - 38) / 2.0;
    self.prevButton.frame = CGRectMake(buttonMargin, buttonMargin, 48, 38);
    self.nextButton.frame = CGRectMake(self.bounds.size.width - 48 - buttonMargin, buttonMargin, 48, 38);
	
    self.calendarContainer.frame = CGRectMake(self.calendarMargin, CGRectGetMaxY(self.titleLabel.frame), containerWidth, containerHeight);
    self.daysHeader.frame = CGRectMake(0, 0, self.calendarContainer.frame.size.width, self.daysHeaderHeight);
	
    CGRect lastDayFrame = CGRectZero;
    for (UILabel *dayLabel in self.dayOfWeekLabels) {
        dayLabel.frame = CGRectMake(CGRectGetMaxX(lastDayFrame) + self.cellBorderWidth, lastDayFrame.origin.y, self.cellWidth, self.daysHeader.frame.size.height);
        lastDayFrame = dayLabel.frame;
    }
	
    for (DateButton *dateButton in self.dateButtons) {
        [dateButton removeFromSuperview];
    }
	
    NSDate *date = [self firstVisibleDate];
	
    NSDate *endDate = [self lastVisibleDate];
	
    NSUInteger dateButtonPosition = 0;
    while ([date laterDate:endDate] != date) {
        DateButton *dateButton = [self.dateButtons objectAtIndex:dateButtonPosition];
		
        dateButton.date = date;
        dateButton.marked = [self.markedDates containsObject:date];
		dateButton.layer.borderColor = [self.selectedDateBorderColor CGColor];
		dateButton.layer.borderWidth = 0.0f;
        if ([self date:dateButton.date isSameDayAsDate:self.selectedDate]) {
            dateButton.backgroundColor = self.selectedDateBackgroundColor;
            [dateButton setTitleColor:self.selectedDateTextColor forState:UIControlStateNormal];
			dateButton.layer.borderWidth = self.cellBorderWidth;
        } else if ([self dateIsToday:dateButton.date]) {
            [dateButton setTitleColor:self.currentDateTextColor forState:UIControlStateNormal];
            dateButton.backgroundColor = self.currentDateBackgroundColor;
        } else if ([date compare:self.minimumDate] == NSOrderedAscending ||
				   [date compare:self.maximumDate] == NSOrderedDescending) {
            [dateButton setTitleColor:self.disabledDateTextColor forState:UIControlStateNormal];
            dateButton.backgroundColor = self.disabledDateBackgroundColor;
        } else if (self.shouldFillCalendar && [self compareByMonth:date toDate:self.monthShowing] != NSOrderedSame) {
            [dateButton setTitleColor:self.nonCurrentMonthDateTextColor forState:UIControlStateNormal];
            dateButton.backgroundColor = [self dateBackgroundColor];
        } else {
            [dateButton setTitleColor:self.dateTextColor forState:UIControlStateNormal];
            dateButton.backgroundColor = [self dateBackgroundColor];
        }
		
		if ([self date:dateButton.date isSameDayAsDate:self.selectedDate])
			dateButton.frame = CGRectInset([self calculateDayCellFrame:date], -self.cellBorderWidth, -self.cellBorderWidth);
		else
			dateButton.frame = [self calculateDayCellFrame:date];
		
        [self.calendarContainer addSubview:dateButton];
		
        date = [self nextDay:date];
        dateButtonPosition++;
    }
}

- (void)setCalendarStartDay:(startDay)calendarStartDay {
    _calendarStartDay = calendarStartDay;
    [self.calendar setFirstWeekday:self.calendarStartDay];
	
    NSUInteger i = 0;
    for (NSString *day in [self getDaysOfTheWeek]) {
        [[self.dayOfWeekLabels objectAtIndex:i] setText:[day uppercaseString]];
        i++;
    }
	
    [self setNeedsLayout];
}

- (void)setMonthShowing:(NSDate *)aMonthShowing {
    NSDate *newMonthShowing = [self firstDayOfMonthContainingDate:aMonthShowing];
    BOOL monthShowingChanged = ![newMonthShowing isEqualToDate:_monthShowing];
    if(monthShowingChanged) {
        _monthShowing = newMonthShowing;
    }
	
    self.titleLabel.text = [self.dateFormatter stringFromDate:_monthShowing];
    CGFloat oldHeight = self.bounds.size.height;
    [self setNeedsLayout];
    if(monthShowingChanged && [self.delegate respondsToSelector:@selector(calendar:didSwitchToMonth:)]) {
        [self.delegate calendar:self didSwitchToMonth:_monthShowing];
    }
    CGFloat newHeight = self.measuredHeight;
    if((oldHeight != newHeight) && [self.delegate respondsToSelector:@selector(calendar:didChangeHeight:)]) {
        [self.delegate calendar:self didChangeHeight:newHeight];
    }
}

- (void)setSelectedDate:(NSDate *)selectedDate {
    _selectedDate = selectedDate;
    [self setNeedsLayout];
    self.monthShowing = selectedDate;
}

- (void)setShouldFillCalendar:(BOOL)shouldFillCalendar {
    _shouldFillCalendar = shouldFillCalendar;
    [self setNeedsLayout];
}

- (void)setDefaultStyle {
    self.backgroundColor = UIColorFromRGB(0x393B40);
	
    _calendarMargin = 5;
    _cornerRadius = 6.0;
    _calendarCornerRadius = 4.0;
    _topHeight = 44.0;
    _daysHeaderHeight = 22.0;
	
    [self setTitleColor:[UIColor whiteColor]];
    [self setTitleFont:[UIFont boldSystemFontOfSize:17.0]];
	
    [self setDayOfWeekFont:[UIFont boldSystemFontOfSize:12.0]];
    [self setDayOfWeekTextColor:UIColorFromRGB(0x999999)];
    [self setDayOfWeekBottomColor:UIColorFromRGB(0xCCCFD5) topColor:[UIColor whiteColor]];
	
    [self setDateFont:[UIFont boldSystemFontOfSize:16.0f]];
    [self setDateTextColor:UIColorFromRGB(0x393B40)];
    [self setDateBackgroundColor:UIColorFromRGB(0xF2F2F2)];
    [self setDateBorderColor:UIColorFromRGB(0xDAE1E6)];
	
	[self setSelectedDateTextColor:UIColorFromRGB(0xF2F2F2)];
	[self setSelectedDateBackgroundColor:UIColorFromRGB(0x88B6DB)];
	[self setSelectedDateBorderColor:UIColorFromRGB(0xDAE1E6)];
	
    [self setCurrentDateTextColor:UIColorFromRGB(0xF2F2F2)];
    [self setCurrentDateBackgroundColor:[UIColor lightGrayColor]];
	
    self.nonCurrentMonthDateTextColor = [UIColor lightGrayColor];
	
    self.disabledDateTextColor = [UIColor lightGrayColor];
    self.disabledDateBackgroundColor = self.dateBackgroundColor;
}

- (CGRect)calculateDayCellFrame:(NSDate *)date {
    NSComparisonResult monthComparison = [self compareByMonth:date toDate:self.monthShowing];
    NSInteger row;
    if (monthComparison == NSOrderedAscending) {
        row = 0;
    } else if (monthComparison == NSOrderedDescending) {
        row = [self numberOfWeeksInMonthContainingDate:self.monthShowing] - 1;
    } else {
        row = [self weekNumberInMonthForDate:date];
    }
    NSInteger placeInWeek = [self placeInWeekForDate:date];
	
    return CGRectMake(placeInWeek * (self.cellWidth + self.cellBorderWidth), (row * (self.cellWidth + self.cellBorderWidth)) + CGRectGetMaxY(self.daysHeader.frame) + self.cellBorderWidth, self.cellWidth, self.cellWidth);
}

- (void)moveCalendarToNextMonth {
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setMonth:1];
    self.monthShowing = [self.calendar dateByAddingComponents:comps toDate:self.monthShowing options:0];
}

- (void)moveCalendarToPreviousMonth {
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    [comps setMonth:-1];
    self.monthShowing = [self.calendar dateByAddingComponents:comps toDate:self.monthShowing options:0];
}

- (void)dateButtonPressed:(id)sender {
    DateButton *dateButton = sender;
    NSDate *date = dateButton.date;
    if (self.minimumDate && [date compare:self.minimumDate] == NSOrderedAscending) {
        return;
    } else if (self.maximumDate && [date compare:self.maximumDate] == NSOrderedDescending) {
        return;
    } else {
        self.selectedDate = date;
        [self.delegate calendar:self didSelectDate:self.selectedDate];
    }
}

#pragma mark - Theming getters/setters

- (void)setTitleFont:(UIFont *)font {
    self.titleLabel.font = font;
}
- (UIFont *)titleFont {
    return self.titleLabel.font;
}

- (void)setTitleColor:(UIColor *)color {
    self.titleLabel.textColor = color;
}
- (UIColor *)titleColor {
    return self.titleLabel.textColor;
}

- (void)setTitleShadowColor:(UIColor*)color {
	self.titleLabel.shadowColor = color;
}
- (UIColor*)titleShadowColor {
	return self.titleLabel.shadowColor;
}

- (void)setTitleShadowOffset:(CGSize)offset {
	self.titleLabel.shadowOffset = offset;
}
- (CGSize)titleShadowOffset {
	return self.titleLabel.shadowOffset;
}

- (void)setButtonColor:(UIColor *)color {
    [self.prevButton setImage:[CKCalendarView imageNamed:@"calendar-header-left-arrow.png" withColor:color] forState:UIControlStateNormal];
    [self.nextButton setImage:[CKCalendarView imageNamed:@"calendar-header-right-arrow.png" withColor:color] forState:UIControlStateNormal];
}

- (void)setInnerBorderColor:(UIColor *)color {
    self.calendarContainer.layer.borderColor = color.CGColor;
}

- (void)setDayOfWeekFont:(UIFont *)font {
    for (UILabel *label in self.dayOfWeekLabels) {
        label.font = font;
    }
}
- (UIFont *)dayOfWeekFont {
    return (self.dayOfWeekLabels.count > 0) ? ((UILabel *)[self.dayOfWeekLabels lastObject]).font : nil;
}

- (void)setDayOfWeekTextColor:(UIColor *)color {
    for (UILabel *label in self.dayOfWeekLabels) {
        label.textColor = color;
    }
}
- (UIColor *)dayOfWeekTextColor {
    return (self.dayOfWeekLabels.count > 0) ? ((UILabel *)[self.dayOfWeekLabels lastObject]).textColor : nil;
}

- (void)setDayOfWeekBottomColor:(UIColor *)bottomColor topColor:(UIColor *)topColor {
    [self.daysHeader setColors:[NSArray arrayWithObjects:topColor, bottomColor, nil]];
}

- (void)setDateFont:(UIFont *)font {
    for (DateButton *dateButton in self.dateButtons) {
        dateButton.titleLabel.font = font;
    }
}
- (UIFont *)dateFont {
    return (self.dateButtons.count > 0) ? ((DateButton *)[self.dateButtons lastObject]).titleLabel.font : nil;
}

- (void)setDateTextColor:(UIColor *)color {
    _dateTextColor = color;
    [self setNeedsLayout];
}

- (void)setDisabledDateTextColor:(UIColor *)color {
    _disabledDateTextColor = color;
    [self setNeedsLayout];
}

- (void)setDateBackgroundColor:(UIColor *)color {
    for (DateButton *dateButton in self.dateButtons) {
        dateButton.backgroundColor = color;
    }
}
- (UIColor *)dateBackgroundColor {
    return (self.dateButtons.count > 0) ? ((DateButton *)[self.dateButtons lastObject]).backgroundColor : nil;
}

- (void)setDateBorderColor:(UIColor *)color {
    self.calendarContainer.backgroundColor = color;
}
- (UIColor *)dateBorderColor {
    return self.calendarContainer.backgroundColor;
}

- (void)setHighlightVisible:(BOOL)highlightVisible {
    _highlightVisible = highlightVisible;
    self.highlight.hidden = !_highlightVisible;
}

- (void)setTopHeight:(CGFloat)topHeight
{
    _topHeight = topHeight;
    [self setNeedsLayout];
}

- (void)setDaysHeaderHeight:(CGFloat)daysHeaderHeight
{
    _daysHeaderHeight = daysHeaderHeight;
    [self setNeedsLayout];
}

#pragma mark - Marking dates
- (void)setMarkedDates:(NSArray *)markedDates
{
    _markedDates = markedDates;
    [self setNeedsLayout];
}

#pragma mark - Calendar helpers

- (NSDate *)firstDayOfMonthContainingDate:(NSDate *)date {
    NSDateComponents *comps = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    comps.day = 1;
    return [self.calendar dateFromComponents:comps];
}

- (NSDate *)firstDayOfNextMonthContainingDate:(NSDate *)date {
    NSDateComponents *comps = [self.calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    comps.day = 1;
    comps.month = comps.month + 1;
    return [self.calendar dateFromComponents:comps];
}

- (NSComparisonResult)compareByMonth:(NSDate *)date toDate:(NSDate *)otherDate {
    NSDateComponents *day = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:date];
    NSDateComponents *day2 = [self.calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:otherDate];
	
    if (day.year < day2.year) {
        return NSOrderedAscending;
    } else if (day.year > day2.year) {
        return NSOrderedDescending;
    } else if (day.month < day2.month) {
        return NSOrderedAscending;
    } else if (day.month > day2.month) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSArray *)getDaysOfTheWeek {
    // adjust array depending on which weekday should be first
    NSArray *weekdays = [self.dateFormatter shortWeekdaySymbols];
    NSUInteger firstWeekdayIndex = [self.calendar firstWeekday] - 1;
    if (firstWeekdayIndex > 0) {
        weekdays = [[weekdays subarrayWithRange:NSMakeRange(firstWeekdayIndex, 7 - firstWeekdayIndex)]
                    arrayByAddingObjectsFromArray:[weekdays subarrayWithRange:NSMakeRange(0, firstWeekdayIndex)]];
    }
    return weekdays;
}

- (NSInteger)placeInWeekForDate:(NSDate *)date {
    NSDateComponents *compsFirstDayInMonth = [self.calendar components:NSWeekdayCalendarUnit fromDate:date];
    return (compsFirstDayInMonth.weekday - 1 - self.calendar.firstWeekday + 8) % 7;
}

- (BOOL)dateIsToday:(NSDate *)date {
    return [self date:[NSDate date] isSameDayAsDate:date];
}

- (BOOL)date:(NSDate *)date1 isSameDayAsDate:(NSDate *)date2 {
    // Both dates must be defined, or they're not the same
    if (date1 == nil || date2 == nil) {
        return NO;
    }
	
    NSDateComponents *day = [self.calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date1];
    NSDateComponents *day2 = [self.calendar components:NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date2];
    return ([day2 day] == [day day] &&
            [day2 month] == [day month] &&
            [day2 year] == [day year] &&
            [day2 era] == [day era]);
}

- (NSInteger)weekNumberInMonthForDate:(NSDate *)date {
    // Return zero-based week in month
    NSInteger placeInWeek = [self placeInWeekForDate:self.monthShowing];
    NSDateComponents *comps = [self.calendar components:(NSDayCalendarUnit) fromDate:date];
    return (comps.day + placeInWeek - 1) / 7;
}

- (NSInteger)numberOfWeeksInMonthContainingDate:(NSDate *)date {
    return [self.calendar rangeOfUnit:NSWeekCalendarUnit inUnit:NSMonthCalendarUnit forDate:date].length;
}

- (NSDate *)nextDay:(NSDate *)date {
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:1];
    return [self.calendar dateByAddingComponents:comps toDate:date options:0];
}

- (NSDate *)previousDay:(NSDate *)date {
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:-1];
    return [self.calendar dateByAddingComponents:comps toDate:date options:0];
}

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color {
    UIImage *img = [UIImage imageNamed:name];
	
    UIGraphicsBeginImageContextWithOptions(img.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
	
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
	
    CGContextSetBlendMode(context, kCGBlendModeColorBurn);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);
	
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
	
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return coloredImg;
}

@end