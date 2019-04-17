//
//  MYFoundationViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/7/31.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYFoundationViewController.h"

@interface MYFoundationViewController ()

@end

@implementation MYFoundationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupMutableStrinig];
}

- (void)setupString {
    
    /*
     NSString->Methods On Protection:
     2、substringFromIndex:
     3、substringToIndex:
     4、substringWithRange:
     5、stringByReplacingCharactersInRange:withString:
     */
    NSString *string = @"abcdefg";
    //    1、characterAtIndex：
    NSLog(@"characterAtIndex:%c",[string characterAtIndex:20]);
    //    2、substringFromIndex:
    NSLog(@"substringFromIndex:%@",[string substringFromIndex:20]);
    //    3、substringToIndex:
    NSLog(@"substringToIndex:%@",[string substringToIndex:20]);
    //    4、substringWithRange:
    NSLog(@"substringWithRange:%@",[string substringWithRange:NSMakeRange(2, 20)]);
    NSLog(@"substringWithRange:%@",[string substringWithRange:NSMakeRange(20, 10)]);
    //    5、stringByReplacingCharactersInRange:withString:
    NSLog(@"stringByReplacingCharactersInRange:%@",[string stringByReplacingCharactersInRange:NSMakeRange(2, 20) withString:@"****"]);
    NSLog(@"stringByReplacingCharactersInRange:%@",[string stringByReplacingCharactersInRange:NSMakeRange(20, 20) withString:@"****"]);
}

- (void)setupMutableStrinig {
    
    /*
     NSMutableString->Methods On Protection:
     1、replaceCharactersInRange:withString:
     2、insertString:atIndex:
     3、deleteCharactersInRange:
     */
    NSMutableString *stringM = [NSMutableString stringWithFormat:@"abcdefg"];
    //    1、replaceCharactersInRange:withString:
    [stringM replaceCharactersInRange:NSMakeRange(2, 20) withString:@"*****"];
    NSLog(@"replaceCharactersInRange:%@",stringM);
    
    //    2、insertString:atIndex:
    stringM = [NSMutableString stringWithFormat:@"abcdefg"];
    [stringM insertString:@"****" atIndex:20];
    NSLog(@"insertString:%@",stringM);
    
    //    3、deleteCharactersInRange:
    stringM = [NSMutableString stringWithFormat:@"abcdefg"];
    [stringM deleteCharactersInRange:NSMakeRange(2, 20)];
    NSLog(@"deleteCharactersInRange:%@",stringM);
    
    stringM = [NSMutableString stringWithFormat:@"abcdefg"];
    [stringM deleteCharactersInRange:NSMakeRange(10, 10)];
    NSLog(@"deleteCharactersInRange:%@",stringM);
}

- (void)setupMutableDictionary {
    
    NSString *value = nil;
    NSString *key = nil;
    //    1、setObject:forKey:
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    [dicM setObject:@"value" forKey:key];
    [dicM setObject:value forKey:@"key"];
    [dicM setObject:@"value" forKey:@"key"];
    NSLog(@"dicM:%@",dicM);
    //    2、removeObjectForKey:
    [dicM removeObjectForKey:key];
    NSLog(@"dicM:%@",dicM);
}

- (void)setupDictionary {
    
    //1 @{nil:nil}
    NSString *value = nil;
    NSString *key = nil;
    NSDictionary *dic = @{@"key":value};
    dic = @{key:@"value"};
    //    2、dictionaryWithObject:forKey：
    [NSDictionary dictionaryWithObject:@"value" forKey:key];
    [NSDictionary dictionaryWithObject:value forKey:@"key"];
    //    3、dictionaryWithObjects:forKeys:
    [NSDictionary dictionaryWithObjects:@[@"1",@"2",@"3"] forKeys:@[@"1",@"2",key]];
}

- (void)setupMutableArray {
    NSString *value = nil;
    
    //0、arrayWithObjects:nil
    NSMutableArray *array0 = [NSMutableArray arrayWithObjects:@"aklkd",value,value, nil];
    NSLog(@"array0:%@",array0);
    //1、objectAtIndex:
    NSMutableArray *array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    NSMutableArray *tempArray = [NSMutableArray array];
    NSString *objectAtIndex = [tempArray objectAtIndex:5];
    objectAtIndex = array1[4];
    
    [array1 removeObject:nil];
    //2、removeObjectAtIndex:
    [array1 removeObjectAtIndex:5];
    //3、removeObjectsInRange:
    [array1 removeObjectsInRange:NSMakeRange(2, 3)];
    NSLog(@"removeObjectsInRangeArray1:%@",array1);
    //4、removeObjectsAtIndexes:
    array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    [array1 removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 4)]];
    NSLog(@"removeObjectsAtIndexesArray:%@",array1);
    //5、insertObject:atIndex:
    array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    [array1 insertObject:@"5" atIndex:5];
    NSLog(@"insertObjectArray:%@",array1);
    //6、insertObjects:atIndexes:
    array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    [array1 insertObjects:@[@"6",@"7",@"8"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(5, 3)]];
    [array1 insertObjects:@[@"6",@"7",@"8"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(3, 3)]];
    [array1 insertObjects:@[@"6",@"7",@"8"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(3, 2)]];
    NSLog(@"insertObjectsAtIndexes%@",array1);
    //7、addObject:nil
    array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    [array1 addObject:value];
    //8、
    array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    [array1 replaceObjectAtIndex:5 withObject:@"5"];
    
    array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    [array1 replaceObjectsInRange:NSMakeRange(1, 4) withObjectsFromArray:@[@"5",@"6",@"7",@"8"]];
    
    array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    [array1 replaceObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 4)] withObjects:@[@"5",@"6",@"7",@"8"]];
    
    array1 = [NSMutableArray arrayWithObjects:@"1",@"2",@"3",@"4", nil];
    [array1 replaceObjectAtIndex:2 withObject:nil];
    
    [array1 setObject:nil atIndexedSubscript:0];
    
    [array1 exchangeObjectAtIndex:18 withObjectAtIndex:15];
}

- (void)setupArray {
    NSString *value = nil;
    //1、@[nil]
    NSArray *array0 = @[value];
    NSLog(@"array0:%@",array0);
    
    //2、objectAtIndex
    NSArray *array2 = @[@"1",@"2",@"3"];
    id objectAtIndex = [array2 objectAtIndex:4];
    array2[4];
    
    //3、objectsAtIndexes:
    NSArray *array3 = @[@"1",@"2",@"3"];
    NSArray *objectsAtIndexes = [array3 objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 2)]];
    NSLog(@"objectsAtIndexes:%@",objectsAtIndexes);
    
    //4、arrayByAddingObject
    [array3 arrayByAddingObject:nil];
    
    //5、indexOfObject
    NSArray *temp = [NSArray array];
    [array3 indexOfObject:@"B" inRange:NSMakeRange(0, 5)];
    
    //6、indexOfObjectIdenticalTo
    [array3 indexOfObjectIdenticalTo:@"B" inRange:NSMakeRange(0, 5)];
    
    //7、subarrayWithRange
    [array3 subarrayWithRange:NSMakeRange(0, 6)];
    
    //8、objectsAtIndexes
    [temp objectsAtIndexes:[NSIndexSet indexSetWithIndex:100]];
    
    [array3 objectAtIndexedSubscript:1000];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
