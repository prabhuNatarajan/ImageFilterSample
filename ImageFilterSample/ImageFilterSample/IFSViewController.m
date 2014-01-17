//
//  IFSViewController.m
//  ImageFilterSample
//
//  Created by Apple on 16/01/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import "IFSViewController.h"
#import "IFSimageViewController.h"
#import "UIimage+FilterCompositions.h"
#import "UIimage+Scale.h"

@implementation IFSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    arrEffects = [[NSMutableArray alloc]initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Original",@"title",@"",@"method", nil], [NSDictionary dictionaryWithObjectsAndKeys:@"E1",@"title",@"e1",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E2",@"title",@"e2",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E3",@"title",@"e3",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E4",@"title",@"e4",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E5",@"title",@"e5",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E6",@"title",@"e6",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E7",@"title",@"e7",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E8",@"title",@"e8",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E9",@"title",@"e9",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E10",@"title",@"e10",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E11",@"title",@"e11",@"method", nil], nil];
    UIBarButtonItem *cam = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(showcam)];
    self.navigationItem.rightBarButtonItem = cam;
    self.title = @"Effects";
    selectedImage = [UIImage imageNamed:@"image.png"];
    thumbImage = [selectedImage scaleToSize:CGSizeMake(320, 320)];
    miniThumbImage = [thumbImage scaleToSize:CGSizeMake(40, 40)];
    self.tableEffects.delegate = self;
    self.tableEffects.dataSource = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showcam
{
    imagePicker = [[UIImagePickerController alloc]init];
    // Set source to the camera
#if (TARGET_IPHONE_SIMULATOR)
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
#else
    imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
#endif
    // Delegate is self
    imagePicker.delegate = self;
    // Allow editing of image ?
    [imagePicker setAllowsEditing:YES];
    // Show image picker
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    arrEffects = [[NSMutableArray alloc]initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Original",@"title",@"",@"method", nil], [NSDictionary dictionaryWithObjectsAndKeys:@"E1",@"title",@"e1",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E2",@"title",@"e2",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E3",@"title",@"e3",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E4",@"title",@"e4",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E5",@"title",@"e5",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E6",@"title",@"e6",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E7",@"title",@"e7",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E8",@"title",@"e8",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E9",@"title",@"e9",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E10",@"title",@"e10",@"method", nil],[NSDictionary dictionaryWithObjectsAndKeys:@"E11",@"title",@"e11",@"method", nil], nil];
    return arrEffects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"EffectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    if (((NSString *)[[arrEffects objectAtIndex:indexPath.row]valueForKey:@"method"]).length > 0)
    {
        SEL _selector = NSSelectorFromString([[arrEffects objectAtIndex:indexPath.row]valueForKey:@"method"]);
        cell.imageView.image = [miniThumbImage performSelector:_selector];
    }
    else
        cell.imageView.image = miniThumbImage;
    cell.textLabel.text = [(NSDictionary *)[arrEffects objectAtIndex:indexPath.row]valueForKey:@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * storyboardName = @"Main";
    NSString * viewControllerID = @"IFSimageViewController";
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    IFSimageViewController * nextViewController = (IFSimageViewController *)[storyboard instantiateViewControllerWithIdentifier:viewControllerID];
    [self presentViewController:nextViewController animated:YES completion:NULL];

    /*IFSimageViewController *nextViewController = [[IFSimageViewController alloc]initWithNibName:@"IFSimageViewController" bundle:nil];
    nextViewController.title = [[arrEffects objectAtIndex:indexPath.row]valueForKey:@"title"];
    [self.navigationController pushViewController:nextViewController animated:YES];*/
    if (((NSString *)[[arrEffects objectAtIndex:indexPath.row]valueForKey:@"method"]) . length > 0)
    {
#ifndef TRACKTIME
        SEL _selector = NSSelectorFromString([[arrEffects objectAtIndex:indexPath.row]valueForKey:@"method"]);
        [nextViewController setImage:[thumbImage performSelector:_selector]];
#else
        SEL _track = NSSelectorFromString(@"trackTime:");
         [nextViewController setImage:[thumbImage performSelector:_track withObject:[[arrEffects objectAtIndex:indexPath.row] valueForKey:@"method"]]];
#endif
    }
    else
    {
        [nextViewController setImage:thumbImage];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //Access the uncropped image from info dictionary
    selectedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    thumbImage = [selectedImage scaleToSize:CGSizeMake(320, 320)];
    miniThumbImage = [thumbImage scaleToSize:CGSizeMake(40, 40)];
    [_tableEffects reloadData];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end