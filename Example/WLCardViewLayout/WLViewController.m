//
//  WLViewController.m
//  WLCardViewLayout
//
//  Created by HotWordland on 02/29/2016.
//  Copyright (c) 2016 HotWordland. All rights reserved.
//

#import "WLViewController.h"
#import "WLCardViewLayout.h"
@interface WLViewController ()<UICollectionViewDataSource,WLSwipeToDeleteCollectionViewLayoutDelegate>
{
    NSUInteger count;
    NSMutableArray *list;
}
@property (weak, nonatomic) IBOutlet WLCardViewLayout *cardLayout;

@end

@implementation WLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    list = [[NSMutableArray alloc]initWithObjects:@"01",@"02",@"03",@"04",nil];
    
    [self.cardLayout setSwipeToDeleteDelegate:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 1;
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return list.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
   
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CardCell" forIndexPath:indexPath];
    UIImageView *im = [cell viewWithTag:100];
    [im setImage:[UIImage imageNamed:list[indexPath.section]]];
    return cell;
}
-(void)swipeToDeleteLayout:(WLCardViewLayout *)layout didDeleteCellAtIndexPath:(NSIndexPath *)indexPath{
    [list removeObjectAtIndex:indexPath.section];
}

@end
