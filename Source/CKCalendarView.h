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

@protocol CKCalendarDelegate;

@interface CKCalendarView : UIView

enum {
    startSunday = 1,
    startMonday = 2,
};
typedef int startDay;

@property (nonatomic) startDay calendarStartDay;
@property (nonatomic, strong) NSDate *minimumDate;
@property (nonatomic, strong) NSDate *maximumDate;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic) BOOL shouldFillCalendar;
@property (nonatomic, weak) id<CKCalendarDelegate> delegate;

- (id)initWithStartDay:(startDay)firstDay;
- (id)initWithStartDay:(startDay)firstDay frame:(CGRect)frame;

// Calculated getters
@property (nonatomic, readonly) CGFloat measuredHeight;
@property (nonatomic, readonly) NSDate *firstVisibleDate;
@property (nonatomic, readonly) NSDate *lastVisibleDate;

// Theming
- (void)setTitleFont:(UIFont *)font;
- (UIFont *)titleFont;

- (void)setTitleColor:(UIColor *)color;
- (UIColor *)titleColor;

- (void)setTitleShadowColor:(UIColor*)color;
- (UIColor*)titleShadowColor;

- (void)setTitleShadowOffset:(CGSize)offset;
- (CGSize)titleShadowOffset;

- (void)setButtonColor:(UIColor *)color;

- (void)setInnerBorderColor:(UIColor *)color;

- (void)setDayOfWeekFont:(UIFont *)font;
- (UIFont *)dayOfWeekFont;

- (void)setDayOfWeekTextColor:(UIColor *)color;
- (UIColor *)dayOfWeekTextColor;

- (void)setDayOfWeekBottomColor:(UIColor *)bottomColor topColor:(UIColor *)topColor;

- (void)setDateFont:(UIFont *)font;
- (UIFont *)dateFont;

- (void)setDateBackgroundColor:(UIColor *)color;
- (UIColor *)dateBackgroundColor;

- (void)setDateBorderColor:(UIColor *)color;
- (UIColor *)dateBorderColor;

@property (nonatomic, strong) UIColor *dateTextColor;
@property (nonatomic, strong) UIColor *selectedDateTextColor;
@property (nonatomic, strong) UIColor *selectedDateBackgroundColor;
@property (nonatomic, strong) UIColor *selectedDateBorderColor;
@property (nonatomic, strong) UIColor *currentDateTextColor;
@property (nonatomic, strong) UIColor *currentDateBackgroundColor;
@property (nonatomic, strong) UIColor *nonCurrentMonthDateTextColor;
@property (nonatomic, strong) UIColor *disabledDateTextColor;
@property (nonatomic, strong) UIColor *disabledDateBackgroundColor;
@property (nonatomic, assign) CGFloat calendarMargin;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat calendarCornerRadius;
@property (nonatomic, assign) BOOL highlightVisible;
@property (nonatomic, assign) CGFloat topHeight;
@property (nonatomic, assign) CGFloat daysHeaderHeight;
@property (nonatomic, assign) CGFloat cellBorderWidth;

// Marking dates
@property (nonatomic, strong) NSArray *markedDates;

@end

@protocol CKCalendarDelegate <NSObject>

- (void)calendar:(CKCalendarView *)calendar didSelectDate:(NSDate *)date;
- (void)calendar:(CKCalendarView *)calendar didSwitchToMonth:(NSDate *)monthShowing;
- (void)calendar:(CKCalendarView *)calendar didChangeHeight:(CGFloat)newHeight;

@end