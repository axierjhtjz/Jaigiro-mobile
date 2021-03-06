//
//  InguruViewController.m
//  jaigiro
//
//  Created by Sergio Garcia on 12/11/13.
//  Copyright (c) 2013 Irontec S.L. All rights reserved.
//

#import "InguruViewController.h"
#import "JaiaFitxaViewController.h"
#import "JaiakViewCell.h"
#import "JaigiroAPIClient.h"
#import "Jaia.h"
#import "UIColor+Jaigiro.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "Login.h"

@interface InguruViewController (){
    NSInteger page, totalPages;
    BOOL emptyShowed;
    BOOL canLoad, isShowingView;
    
    CLLocation *actualPosition;
    NSMutableArray *jaiakArray;
}

@end

@implementation InguruViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    canLoad = YES;
    //iniciamos la ubicacion
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //back button for the next view
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Atzera" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    [self.view addSubview:self.emptyView];
    emptyShowed = YES;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"JaiakViewCell" bundle:nil] forCellReuseIdentifier:@"JaiaCell"];
    jaiakArray = [[NSMutableArray alloc]init];
    [jaiakArray removeAllObjects];
}

- (void)viewWillAppear:(BOOL)animated
{
    isShowingView = YES;
    if(_isCalendar){
        page = 1;
        [locationManager stopUpdatingLocation];
        if(canLoad){
            canLoad = NO;
            [self firstLoadDataJaiak];
        }
        
    }else{
        [locationManager startUpdatingLocation];
    }
    
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    //quitar seleccion de la tabla
    NSIndexPath *selection = [self.tableView indexPathForSelectedRow];
    if (selection) {
        [self.tableView deselectRowAtIndexPath:selection animated:YES];
    }
    
    [locationManager stopUpdatingLocation];
    isShowingView = NO;
}


#pragma mark Location manager

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *loc = [locations lastObject];
    
    [locationManager stopUpdatingLocation];
    actualPosition = loc;
    page = 1;
    
    if(canLoad){
        canLoad = NO;
        [self firstLoadDataJaiak];
    }
    NSLog(@"Location %f %f", loc.coordinate.latitude, loc.coordinate.longitude);
    
}

#pragma mark Load data

-(void) firstLoadDataJaiak
{
    NSMutableDictionary *params = [Login getLoginParams];
    NSString *path;
    if(!_isCalendar){
        [params setValue:[NSString stringWithFormat:@"%f", actualPosition.coordinate.latitude] forKey:@"lat"];
        [params setValue:[NSString stringWithFormat:@"%f", actualPosition.coordinate.longitude] forKey:@"lng"];
        [params setValue:[NSString stringWithFormat:@"%d", [Login getMaxDistance]] forKey:@"maxDistance"];
    }
    if (_dateLimit){
        [params setValue:_dateLimit forKey:@"dateLimit"];
        path = @"get-jaiak";
    }else{
        [params setValue:[Login getMaxDateForAPI] forKey:@"dateLimit"];
        path = @"get-jaiak-by-coords";
        
    }
    [params setValue:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    [params setValue:@"21" forKey:@"items"];
    
    [[JaigiroAPIClient sharedClient] postPath:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        totalPages = [[responseObject objectForKey:@"orriKop"] integerValue];
        
        [jaiakArray removeAllObjects];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        
        
        NSMutableArray *jai = [responseObject objectForKey:@"jaiak"];
        
        NSInteger tam;
        @try {
            tam = jai.count;
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
            tam = 0;
        }
        
        NSInteger colSel=0;
        for(NSInteger x=0;x<tam;x++){
            Jaia *j = [[Jaia alloc]init];
            j.banator = [[[jai objectAtIndex:x]objectForKey:@"banator"] integerValue];
            NSString *dateString = [[jai objectAtIndex:x]objectForKey:@"bukaera"];
            j.bukaera = [dateFormatter dateFromString:dateString];
            j.deskribapena = [[jai objectAtIndex:x]objectForKey:@"deskribapena"];
            dateString = [[jai objectAtIndex:x]objectForKey:@"hasiera"];
            j.hasiera = [dateFormatter dateFromString:dateString];
            j.herria = [[jai objectAtIndex:x]objectForKey:@"herria"];
            j.id_jaia = [[[jai objectAtIndex:x]objectForKey:@"id"] integerValue];
            j.izena = [[jai objectAtIndex:x]objectForKey:@"izena"];
            j.url_kartela = [[jai objectAtIndex:x]objectForKey:@"kartela"];
            j.lat = [[[jai objectAtIndex:x]objectForKey:@"lat"] floatValue];
            j.lng = [[[jai objectAtIndex:x]objectForKey:@"lng"] floatValue];
            j.pisua = [[[jai objectAtIndex:x]objectForKey:@"pisua"] integerValue];
            j.url_thum = [[jai objectAtIndex:x]objectForKey:@"thumb"];
            
            j.colorSelector = colSel;
            colSel++;
            if(colSel == 3){
                colSel = 0;
            }
            [jaiakArray addObject:j];
        }
        
        if(tam == 0){
            self.emptyText.text = @"Ez dira jaiak aurkitu..";
        }else{
            [self.emptyView removeFromSuperview];
            self.emptyText.text = @"Oraindik ez da zure posizioa zehaztatu...";
            emptyShowed = NO;
        }
        [self.tableView reloadData];
        page++;
        canLoad = YES;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(isShowingView){
            [self firstLoadDataJaiak];
        }
        //        NSLog(@"TIMEOUT");
    }];
    
}


-(void) loadDataJaiak
{
    NSMutableDictionary *params = [Login getLoginParams];
    NSString *path;
    if(!_isCalendar){
        [params setValue:[NSString stringWithFormat:@"%f", actualPosition.coordinate.latitude] forKey:@"lat"];
        [params setValue:[NSString stringWithFormat:@"%f", actualPosition.coordinate.longitude] forKey:@"lng"];
        [params setValue:[NSString stringWithFormat:@"%d", [Login getMaxDistance]] forKey:@"maxDistance"];
    }
    if (_dateLimit){
        [params setValue:_dateLimit forKey:@"dateLimit"];
        path = @"get-jaiak";
    }else{
        [params setValue:[Login getMaxDateForAPI] forKey:@"dateLimit"];
        path = @"get-jaiak-by-coords";
        
    }
    [params setValue:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    [params setValue:@"21" forKey:@"items"];
    
    [[JaigiroAPIClient sharedClient] postPath:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        totalPages = [[responseObject objectForKey:@"orriKop"] integerValue];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        
        
        NSMutableArray *jai = [responseObject objectForKey:@"jaiak"];
        
        NSInteger tam;
        @try {
            tam = jai.count;
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
            tam = 0;
        }
        
        NSInteger colSel=0;
        for(NSInteger x=0;x<tam;x++){
            Jaia *j = [[Jaia alloc]init];
            j.banator = [[[jai objectAtIndex:x]objectForKey:@"banator"] integerValue];
            NSString *dateString = [[jai objectAtIndex:x]objectForKey:@"bukaera"];
            j.bukaera = [dateFormatter dateFromString:dateString];
            j.deskribapena = [[jai objectAtIndex:x]objectForKey:@"deskribapena"];
            dateString = [[jai objectAtIndex:x]objectForKey:@"hasiera"];
            j.hasiera = [dateFormatter dateFromString:dateString];
            j.herria = [[jai objectAtIndex:x]objectForKey:@"herria"];
            j.id_jaia = [[[jai objectAtIndex:x]objectForKey:@"id"] integerValue];
            j.izena = [[jai objectAtIndex:x]objectForKey:@"izena"];
            j.url_kartela = [[jai objectAtIndex:x]objectForKey:@"kartela"];
            j.lat = [[[jai objectAtIndex:x]objectForKey:@"lat"] floatValue];
            j.lng = [[[jai objectAtIndex:x]objectForKey:@"lng"] floatValue];
            j.pisua = [[[jai objectAtIndex:x]objectForKey:@"pisua"] integerValue];
            j.url_thum = [[jai objectAtIndex:x]objectForKey:@"thumb"];
            
            j.colorSelector = colSel;
            colSel++;
            if(colSel == 3){
                colSel = 0;
            }
            [jaiakArray addObject:j];
        }
        
        if(tam == 0){
            self.emptyText.text = @"Ez dira jaiak aurkitu..";
        }else{
            [self.emptyView removeFromSuperview];
            self.emptyText.text = @"Oraindik ez da zure posizioa zehaztatu...";
            emptyShowed = NO;
        }
        [self.tableView reloadData];
        page++;
        canLoad = YES;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self loadDataJaiak];
        //        NSLog(@"TIMEOUT");
    }];
    
}




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return jaiakArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JaiakViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JaiaCell"];
    
    Jaia *j=[jaiakArray objectAtIndex:indexPath.row];
    
    cell.lblNombreFiesta.text = [[@" " stringByAppendingString:j.izena] stringByAppendingString:@" "];
    cell.lblPueblo.text = [j.herria uppercaseString];
    [cell.lblPueblo sizeToFit];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *stringFromDate = [[dateFormatter stringFromDate:j.hasiera] stringByAppendingString:@" - "];
    stringFromDate = [stringFromDate stringByAppendingString:[dateFormatter stringFromDate:j.bukaera]];
    cell.lblFecha.text = stringFromDate;
    
    [cell.imgKartela setImageWithURL:[NSURL URLWithString:j.url_thum]];
    [self setColors:indexPath.row cell:cell jaia:j];
    return cell;
}

-(void)setColors:(NSInteger)index cell:(JaiakViewCell *)cell jaia:(Jaia *)jaia
{
    UIColor *c = [UIColor_Jaigiro getColor:jaia.colorSelector];
    if(index%2 == 0){
        //normal
        //fondo color
        cell.dataView.backgroundColor = c;
        cell.lblPueblo.textColor = c;
        cell.lblPueblo.backgroundColor = [UIColor whiteColor];
        cell.lblFecha.textColor = [UIColor whiteColor];
        cell.lblFecha.backgroundColor = c;
        cell.lblNombreFiesta.textColor = [UIColor whiteColor];
        cell.lblNombreFiesta.backgroundColor = c;
    }else{
        //inverso
        //fondo blanco
        cell.dataView.backgroundColor = [UIColor whiteColor];
        cell.lblPueblo.textColor = [UIColor whiteColor];
        cell.lblPueblo.backgroundColor = c;
        cell.lblFecha.textColor = c;
        cell.lblFecha.backgroundColor = [UIColor whiteColor];
        cell.lblNombreFiesta.textColor = c;
        cell.lblNombreFiesta.backgroundColor = [UIColor whiteColor];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Jaia *j = [jaiakArray objectAtIndex:indexPath.row];
    
    JaiaFitxaViewController *vc = [[JaiaFitxaViewController alloc]init];
    vc.jaia = j;
    [self.navigationController pushViewController:vc animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger lastRow=[jaiakArray count]-1;
    if([indexPath row] == (lastRow - 3) && page <= totalPages)
    {
        if(canLoad){
            canLoad = NO;
            [self loadDataJaiak];
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 73;
}

@end
