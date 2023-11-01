import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:resturant_delivery_boy/data/model/response/order_details_model.dart';
import 'package:resturant_delivery_boy/data/model/response/order_model.dart';
import 'package:resturant_delivery_boy/helper/date_converter.dart';
import 'package:resturant_delivery_boy/helper/price_converter.dart';
import 'package:resturant_delivery_boy/localization/language_constrants.dart';
import 'package:resturant_delivery_boy/provider/auth_provider.dart';
import 'package:resturant_delivery_boy/provider/localization_provider.dart';
import 'package:resturant_delivery_boy/provider/order_provider.dart';
import 'package:resturant_delivery_boy/provider/splash_provider.dart';
import 'package:resturant_delivery_boy/provider/theme_provider.dart';
import 'package:resturant_delivery_boy/provider/time_provider.dart';
import 'package:resturant_delivery_boy/provider/tracker_provider.dart';
import 'package:resturant_delivery_boy/utill/app_constants.dart';
import 'package:resturant_delivery_boy/utill/dimensions.dart';
import 'package:resturant_delivery_boy/utill/images.dart';
import 'package:resturant_delivery_boy/utill/styles.dart';
import 'package:resturant_delivery_boy/view/base/custom_button.dart';
import 'package:resturant_delivery_boy/view/screens/chat/chat_screen.dart';
import 'package:resturant_delivery_boy/view/screens/home/widget/order_widget.dart';
import 'package:resturant_delivery_boy/view/screens/order/order_place_screen.dart';
import 'package:resturant_delivery_boy/view/screens/order/widget/custom_divider.dart';
import 'package:resturant_delivery_boy/view/screens/order/widget/delivery_dialog.dart';
import 'package:resturant_delivery_boy/view/screens/order/widget/permission_dialog.dart';
import 'package:resturant_delivery_boy/view/screens/order/widget/slider_button.dart';
import 'package:resturant_delivery_boy/view/screens/order/widget/timer_view.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel orderModelItem;
  OrderDetailsScreen({this.orderModelItem});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderModel orderModel;


  @override
  void initState() {
    orderModel = widget.orderModelItem;

    _loadData();


    super.initState();
  }

  _loadData() {
    if(orderModel.orderAmount == null) {
      Provider.of<OrderProvider>(context, listen: false).getOrderModel('${orderModel.id}').then((OrderModel value) {
        orderModel = value;
      }).then((value) {
        Provider.of<OrderProvider>(context, listen: false).getOrderDetails(orderModel.id.toString(), context).then((value) {
          Provider.of<TimerProvider>(context, listen: false).countDownTimer(orderModel, context);
        });
      });
    }else{
      Provider.of<OrderProvider>(context, listen: false).getOrderDetails(orderModel.id.toString(), context).then((value) {
        Provider.of<TimerProvider>(context, listen: false).countDownTimer(orderModel, context);
      });
    }
  }


  @override
  Widget build(BuildContext context) {



    double deliveryCharge = 0;
    if(orderModel.orderType == 'delivery') {
      deliveryCharge = orderModel.deliveryCharge;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).textTheme.bodyText1.color,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          getTranslated('order_details', context),
          style: Theme.of(context).textTheme.headline3.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).textTheme.bodyText1.color),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, order, child) {

          double _itemsPrice = 0;
          double _discount = 0;
          double _tax = 0;
          double _addOns = 0;
          double _subTotal = 0;
          double totalPrice = 0;
          if (order.orderDetails != null && orderModel.orderAmount != null) {
            order.orderDetails.forEach((orderDetails) {
              // int _index = 0;

              if(orderDetails.addOnIds != null){
                orderDetails.addOnIds.forEach((_addOnsId) {
                  orderDetails.productDetails.addOns.forEach((_addons) {
                    if(_addons.id == _addOnsId) {
                      _addOns = _addOns + (_addons.price * orderDetails.addOnQtys[orderDetails.addOnIds.indexOf(_addOnsId)]);
                      // _index++;
                    }
                  });
                });
              }

              _itemsPrice = _itemsPrice + (orderDetails.quantity * (orderDetails.quantity == 0.5 ? AppConstants.HALF_HALF_PRICE : orderDetails.price));
              _discount = _discount + (orderDetails.discountOnProduct * orderDetails.quantity);
              _tax = _tax + (orderDetails.taxAmount * orderDetails.quantity);
            });
            _itemsPrice = _itemsPrice + _addOns;
            _subTotal = _itemsPrice + _tax;
             totalPrice = _subTotal - _discount + deliveryCharge - orderModel.couponDiscountAmount;
          }


          return order.orderDetails != null && orderModel.orderAmount != null
              ? Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                      children: [
                        Row(children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text('${getTranslated('order_id', context)}', style: rubikRegular.copyWith(color: Theme.of(context).highlightColor)),
                                Text(' # ${orderModel.id}', style: rubikMedium.copyWith(color: Theme.of(context).highlightColor)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.watch_later, size: 17),
                                SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                orderModel.deliveryTime == null ? Text(DateConverter.isoStringToLocalDateOnly(orderModel.createdAt),
                                  style: rubikRegular.copyWith(color: Theme.of(context).highlightColor),
                                ) : Flexible(
                                  child: Text(
                                    DateConverter.deliveryDateAndTimeToDate(orderModel.deliveryDate, orderModel.deliveryTime, context),
                                    style: rubikRegular.copyWith(color: Theme.of(context).highlightColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),

                        if(orderModel.orderStatus == 'pending'
                            || orderModel.orderStatus == 'confirmed'
                            || orderModel.orderStatus == 'processing'
                            || orderModel.orderStatus == 'out_for_delivery'
                        ) TimerView(),


                        SizedBox(height: 20),

                        Container(
                          padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColorDark,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(
                              color: Colors.grey[Provider.of<ThemeProvider>(context).darkTheme ? 700 : 300],
                              blurRadius: 5, spreadRadius: 1,
                            )],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.PADDING_SIZE_LARGE),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(getTranslated('customer', context), style: rubikRegular.copyWith(
                                    fontSize: Dimensions.FONT_SIZE_EXTRA_SMALL,
                                    color: Theme.of(context).highlightColor,
                                  )),
                                ],
                              ),
                            ),
                            ListTile(
                              leading: ClipOval(
                                child: FadeInImage.assetNetwork(
                                  placeholder: Images.placeholder_user, height: 40, width: 40, fit: BoxFit.cover,
                                  image: orderModel.customer != null
                                      ? '${Provider.of<SplashProvider>(context, listen: false).baseUrls.customerImageUrl}/${orderModel.customer.image ?? ''}' : '',
                                  imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholder_user, height: 40, width: 40, fit: BoxFit.cover),
                                ),
                              ),
                              title: Text(
                                '${orderModel.deliveryAddress?.contactPersonName ?? ''}',
                                style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor),
                              ),
                              trailing: InkWell(
                                onTap: () {
                                  launchUrl(Uri.parse('tel:${orderModel.deliveryAddress.contactPersonNumber}'));
                                },
                                child: Container(
                                  padding: EdgeInsets.all(Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).shadowColor),
                                  child: Icon(Icons.call_outlined, color: Colors.black),
                                ),
                              ),
                            ),

                          ]),
                        ),
                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Text('${getTranslated('item', context)}:', style: rubikRegular.copyWith(color: Theme.of(context).highlightColor)),
                              SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                              Text(order.orderDetails.length.toString(), style: rubikMedium.copyWith(color: Theme.of(context).primaryColor)),
                            ]),
                            orderModel.orderStatus == 'processing' || orderModel.orderStatus == 'out_for_delivery'
                                ? Row(children: [
                                    Text('${getTranslated('payment_status', context)}:',
                                        style: rubikRegular.copyWith(color: Theme.of(context).highlightColor)),
                                    SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                    Text(getTranslated('${orderModel.paymentStatus}', context),
                                        style: rubikMedium.copyWith(color: Theme.of(context).primaryColor)),
                                  ])
                                : SizedBox.shrink(),
                          ],
                        ),
                        Divider(height: 20),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: order.orderDetails.length,
                          itemBuilder: (context, index) {
                            List<AddOns> _addOns = [];

                            if(order.orderDetails[index].addOnIds != null){
                              order.orderDetails[index].addOnIds.forEach((_addOnsId) {
                                order.orderDetails[index].productDetails.addOns.forEach((_addons) {
                                  if(_addons.id == _addOnsId) {
                                    _addOns.add(_addons);
                                  }
                                });
                              });
                            }

                            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: FadeInImage.assetNetwork(
                                    placeholder: Images.placeholder_image, height: 70, width: 80, fit: BoxFit.cover,
                                    image: '${Provider.of<SplashProvider>(context, listen: false).baseUrls.productImageUrl}/${order.orderDetails[index].productDetails.image}',
                                    imageErrorBuilder: (c, o, s) => Image.asset(Images.placeholder_image, height: 70, width: 80, fit: BoxFit.cover),
                                  ),
                                ),
                                SizedBox(width: Dimensions.PADDING_SIZE_SMALL),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            order.orderDetails[index].productDetails.name,
                                            style: rubikMedium.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL, color: Theme.of(context).highlightColor),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(getTranslated('amount', context), style: rubikRegular.copyWith(color: Theme.of(context).highlightColor)),
                                      ],
                                    ),
                                    SizedBox(height: Dimensions.PADDING_SIZE_EXTRA_SMALL),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Row(
                                        children: [
                                          Text('${getTranslated('quantity', context)}:',
                                              style: rubikRegular.copyWith(color: Theme.of(context).highlightColor)),
                                          Text(' ${order.orderDetails[index].quantity == 0.5 ? 'Half' : order.orderDetails[index].quantity.toInt()}',
                                              style: rubikMedium.copyWith(color: Theme.of(context).primaryColor)),
                                        ],
                                      ),
                                      order.orderDetails[index].quantity != 0.5 ? Text(
                                        PriceConverter.convertPrice(context, order.orderDetails[index].price),
                                        style: rubikMedium.copyWith(color: Theme.of(context).primaryColor),
                                      ) : SizedBox(),
                                    ]),
                                    SizedBox(height: Dimensions.PADDING_SIZE_SMALL),


                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        order.orderDetails[index].variation != null ? Row(children: [
                                          order.orderDetails[index].variation.type != null ?
                                          Container(height: 10, width: 10, decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Theme.of(context).textTheme.bodyText1.color,
                                          )) : SizedBox.shrink(),
                                          SizedBox(width: Dimensions.PADDING_SIZE_EXTRA_SMALL),

                                          Text(order.orderDetails[index].variation.type ?? '',
                                            style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_SMALL),
                                          ),
                                        ]) :SizedBox(),

                                        ProductTypeView(productType: order.orderDetails[index].productDetails.productType),
                                      ],
                                    ) ,
                                  ]),
                                ),
                              ]),
                              _addOns.length > 0
                                  ? SizedBox(
                                      height: 30,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        physics: BouncingScrollPhysics(),
                                        padding: EdgeInsets.only(top: Dimensions.PADDING_SIZE_SMALL),
                                        itemCount: _addOns.length,
                                        itemBuilder: (context, i) {
                                          return Padding(
                                            padding: EdgeInsets.only(right: Dimensions.PADDING_SIZE_SMALL),
                                            child: Row(children: [
                                              Text(_addOns[i].name, style: rubikRegular.copyWith(color: Theme.of(context).highlightColor)),
                                              SizedBox(width: 2),
                                              // Text(
                                              //   PriceConverter.convertPrice(context, _addOns[i].price),
                                              //   style: rubikMedium.copyWith(color: Theme.of(context).highlightColor),
                                              // ),
                                              // SizedBox(width: 2),
                                              Text('(${order.orderDetails[index].addOnQtys[i]})', style: rubikRegular),
                                            ]),
                                          );
                                        },
                                      ),
                                    )
                                  : SizedBox(),
                              Divider(height: 20),
                            ]);
                          },
                        ),

                        (orderModel.orderNote != null && orderModel.orderNote.isNotEmpty) ? Container(
                          padding: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                          margin: EdgeInsets.only(bottom: Dimensions.PADDING_SIZE_LARGE),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(width: 1, color: Theme.of(context).hintColor),
                          ),
                          child: Text(orderModel.orderNote, style: rubikRegular.copyWith(color: Theme.of(context).hintColor)),
                        ) : SizedBox(),

                        // Total
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(getTranslated('items_price', context), style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE)),
                          Text(PriceConverter.convertPrice(context, _itemsPrice), style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE)),
                        ]),
                        SizedBox(height: 10),

                        // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        //   Text(getTranslated('tax', context),
                        //       style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                        //   Text('(+) ${PriceConverter.convertPrice(context, _tax)}',
                        //       style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                        // ]),
                        // SizedBox(height: 10),

                        // Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        //   Text(getTranslated('addons', context),
                        //       style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                        //   Text('(+) ${PriceConverter.convertPrice(context, _addOns)}',
                        //       style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                        // ]),

                        Padding(
                          padding: EdgeInsets.symmetric(vertical: Dimensions.PADDING_SIZE_SMALL),
                          child: CustomDivider(),
                        ),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(getTranslated('subtotal', context),
                              style: rubikMedium.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                          Text(PriceConverter.convertPrice(context, _subTotal),
                              style: rubikMedium.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                        ]),
                        SizedBox(height: 10),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(getTranslated('discount', context),
                              style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                          Text('(-) ${PriceConverter.convertPrice(context, _discount)}',
                              style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                        ]),
                        SizedBox(height: 10),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(getTranslated('coupon_discount', context),
                              style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                          Text(
                            '(-) ${PriceConverter.convertPrice(context, orderModel.couponDiscountAmount)}',
                            style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor),
                          ),
                        ]),
                        SizedBox(height: 10),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(getTranslated('delivery_fee', context),
                              style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                          Text('(+) ${PriceConverter.convertPrice(context, deliveryCharge)}',
                              style: rubikRegular.copyWith(fontSize: Dimensions.FONT_SIZE_LARGE, color: Theme.of(context).highlightColor)),
                        ]),

                        Padding(
                          padding: EdgeInsets.symmetric(vertical: Dimensions.PADDING_SIZE_SMALL),
                          child: CustomDivider(),
                        ),

                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(getTranslated('total_amount', context),
                              style: rubikMedium.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_LARGE, color: Theme.of(context).primaryColor)),
                          Text(
                            PriceConverter.convertPrice(context, totalPrice),
                            style: rubikMedium.copyWith(fontSize: Dimensions.FONT_SIZE_EXTRA_LARGE, color: Theme.of(context).primaryColor),
                          ),
                        ]),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                   orderModel.orderStatus == 'processing' || orderModel.orderStatus == 'out_for_delivery'
                      ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                          child: SizedBox(
                          width: 1170,
                            child: CustomButton(
                            btnTxt: getTranslated('direction', context),
                            onTap: () {
                              _checkPermission(context, () {
                                Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((position) {
                                  MapUtils.openMap(
                                      double.parse(orderModel.deliveryAddress.latitude) ?? 23.8103,
                                      double.parse(orderModel.deliveryAddress.longitude) ?? 90.4125,
                                      position.latitude ?? 23.81,
                                      position.longitude ?? 90.4125);
                                });
                              });

                            }),
                          ),
                        ),
                      )
                      : SizedBox.shrink(),

                  orderModel.orderStatus != 'delivered' ? Center(
                    child: Container(
                      width: 1170,
                      padding: const EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                      child: CustomButton(btnTxt: getTranslated('chat_with_customer', context), onTap: (){
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(orderModel: orderModel)));
                      }),
                    ),
                  ) : SizedBox(),

                  orderModel.orderStatus == 'done' || orderModel.orderStatus == 'processing' ? Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.PADDING_SIZE_SMALL),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.05)),
                      color: Theme.of(context).backgroundColor,
                    ),
                    child: Transform.rotate(
                      angle: Provider.of<LocalizationProvider>(context).isLtr ? pi * 2 : pi, // in radians
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: SliderButton(
                          action: () {
                            _checkPermission(context, () {
                              Provider.of<TrackerProvider>(context, listen: false).setOrderID(orderModel.id);
                              Provider.of<TrackerProvider>(context, listen: false).startLocationService();
                              String token = Provider.of<AuthProvider>(context, listen: false).getUserToken();
                              Provider.of<OrderProvider>(context, listen: false)
                                  .updateOrderStatus(token: token, orderId: orderModel.id, status: 'out_for_delivery');
                              Provider.of<OrderProvider>(context, listen: false).getAllOrders(context);
                              Navigator.pop(context);
                            });
                          },

                          ///Put label over here
                          label: Text(
                            getTranslated('swip_to_deliver_order', context),
                            style: Theme.of(context).textTheme.headline3.copyWith(color: Theme.of(context).primaryColor),
                          ),
                          dismissThresholds: 0.5,
                          dismissible: false,
                          icon: Center(
                              child: Icon(
                                Icons.double_arrow_sharp,
                                color: Colors.white,
                                size: 20.0,
                                semanticLabel: 'Text to announce in accessibility modes',
                              )),

                          ///Change All the color and size from here.
                          radius: 10,
                          boxShadow: BoxShadow(blurRadius: 0.0),
                          buttonColor: Theme.of(context).primaryColor,
                          backgroundColor: Theme.of(context).backgroundColor,
                          baseColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  )
                      : orderModel.orderStatus == 'out_for_delivery'
                      ? Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.all(Dimensions.PADDING_SIZE_SMALL),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.PADDING_SIZE_SMALL),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.05)),
                      color: Theme.of(context).backgroundColor,
                    ),
                    child: Transform.rotate(
                      angle: Provider.of<LocalizationProvider>(context).isLtr ? pi * 2 : pi, // in radians
                      child: Directionality(
                        textDirection: TextDirection.ltr, // set it to rtl
                        child: SliderButton(
                          action: () {
                            String token = Provider.of<AuthProvider>(context, listen: false).getUserToken();

                            if (orderModel.paymentStatus == 'paid') {
                              Provider.of<TrackerProvider>(context, listen: false).stopLocationService();
                              Provider.of<OrderProvider>(context, listen: false)
                                  .updateOrderStatus(token: token, orderId: orderModel.id, status: 'delivered',);
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => OrderPlaceScreen(orderID: orderModel.id.toString())));
                            } else {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                      child: DeliveryDialog(
                                        onTap: () {},
                                        totalPrice: totalPrice,
                                        orderModel: orderModel,
                                      ),
                                    );
                                  });
                            }
                          },

                          ///Put label over here
                          label: Text(
                            getTranslated('swip_to_confirm_order', context),
                            style: Theme.of(context).textTheme.headline3.copyWith(color: Theme.of(context).primaryColor),
                          ),
                          dismissThresholds: 0.5,
                          dismissible: false,
                          icon: Center(
                              child: Icon(
                                Icons.double_arrow_sharp,
                                color: Colors.white,
                                size: 20.0,
                                semanticLabel: 'Text to announce in accessibility modes',
                              )),

                          ///Change All the color and size from here.
                          radius: 10,
                          boxShadow: BoxShadow(blurRadius: 0.0),
                          buttonColor: Theme.of(context).primaryColor,
                          backgroundColor: Theme.of(context).backgroundColor,
                          baseColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  )
                      : SizedBox.shrink(),

                ],
              )
              : Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)));
        },
      ),
    );
  }

  void _checkPermission(BuildContext context, Function callback) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      showDialog(context: context, builder: (context) => PermissionDialog(isDenied: true, onPressed: () async {
        Navigator.pop(context);
        await Geolocator.requestPermission();
        _checkPermission(context, callback);
      }));
    }else if(permission == LocationPermission.deniedForever) {
      showDialog(context: context, builder: (context) => PermissionDialog(isDenied: false, onPressed: () async {
        Navigator.pop(context);
        await Geolocator.openAppSettings();
        _checkPermission(context, callback);
      }));
    }else {
      callback();
    }
  }
}


class ProductTypeView extends StatelessWidget {
  final String productType;
  const ProductTypeView({Key key, this.productType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return productType == null ? SizedBox() : Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        color: Theme.of(context).primaryColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0 ,vertical: 2),
        child: Text(getTranslated(productType, context,
        ) ?? "", style: rubikRegular.copyWith(color: Colors.white, fontSize: Dimensions.FONT_SIZE_SMALL),
        ),
      ),
    );
  }
}
