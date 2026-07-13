import 'package:get/get.dart';
import 'package:graba2z/Api/Models/newProductModel.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/favController.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';
import 'package:graba2z/Views/Product%20Folder/newProduct_card.dart';

import 'package:graba2z/Utils/popup_helper.dart';
import '../../../../Utils/packages.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}
class _FavoriteState extends State<Favorite> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PopupHelper.showIfNeeded(context, 'wishlist');
      }
    });
  }

  void _handleBack() {
    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    if (Get.isRegistered<BottomNavigationController>()) {
      Get.find<BottomNavigationController>().setTabIndex(0);
    }
  }

  void _showAddedToCartPopup() {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Added to cart',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _showWishlistPopup({required bool added}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(40)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(added ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    added ? 'Added to wishlist' : 'Removed from wishlist',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (entry.mounted) entry.remove();
    });
  }

  // Map model to the structure NewProductCard expects
  Map<String, dynamic> _modelToMap(Newproductmodel m) {
    String mainImage = m.image ?? '';
    if (m.galleryImages != null && m.galleryImages!.isNotEmpty) {
      mainImage = m.galleryImages!.first ?? '';
    }
    return {
      '_id': m.id ?? '',
      'name': m.name ?? '',
      'image': ImageHelper.getUrl(mainImage),
      'galleryImages': m.galleryImages ?? const <String>[],
      'offerPrice': m.offerPrice ?? 0,
      'price': m.price ?? 0,
      'stockStatus': m.stockStatus ?? '',
      'sku': m.sku ?? '',
      'description': m.description ?? '',
      'shortDescription': m.shortDescription ?? '',
      'brand': {'name': m.brand?.name ?? ''},
      'parentCategory': {
        '_id': m.parentCategory?.id ?? '',
        'name': m.parentCategory?.name ?? ''
      },
      'specifications': m.specifications ?? const [],
      'reviews': m.reviews ?? const [],
      'discount': m.discount ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = FavoriteController.of(context, listen: true);
    final favoriteList = provider.favorites;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          showLeading: true,
          leadingWidget: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios, size: 20),
          ),
          titleText: "Favorites",
          actionicon: GetBuilder<CartNotifier>(
            builder: (
              cartNotifier,
            ) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  // The cart icon
                  GestureDetector(
                    onTap: () {
                      context.route(Cart());
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: Image.asset(
                        "assets/icons/addcart.png",
                        color: kdefwhiteColor,
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                  // The dynamic badge showing cart count
                  if (cartNotifier.cartOtherInfoList.isNotEmpty) ...[
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: kredColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cartNotifier.cartOtherInfoList.length.toString(),
                          style: const TextStyle(
                            color: kdefwhiteColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        body: SafeArea(
          child: GetBuilder<AuthController>(builder: (
            authProvider,
          ) {
          int getCrossAxisCount(BuildContext context) {
            final width = MediaQuery.of(context).size.width;
            if (width >= 1100) return 8;
            if (width >= 800) return 7;
            if (width >= 600) return 6;
            return 3;
          }

          double getAspectRatio(BuildContext context) {
            final width = MediaQuery.of(context).size.width;
            if (width >= 1100) return 0.75;
            if (width >= 800) return 0.7;
            if (width >= 600) return 0.65;
            return 0.65;
          }

          if (!authProvider.userID.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: defaultPadding(),
                    child: Image.asset(
                      'assets/images/login.png',
                    ),
                  ),
                  20.0.heightbox,
                  const Text(
                    "First login to Favorite the product",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kSecondaryColor,
                    ),
                  ),
                  30.0.heightbox,
                  PrimaryButton(
                    // width: context.width,
                    onPressFunction: () {
                      context.route(Login());
                    },
                    buttonText: "Login Now",
                  ),
                ],
              ),
            );
          }

          return favoriteList.isEmpty
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: defaultPadding(),
                      child: Image.asset(
                        'assets/images/nofav.png',
                      ),
                    ),
                    20.0.heightbox,
                    const Text(
                      "No Favorite Items",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kSecondaryColor,
                      ),
                    ),
                    10.0.heightbox,
                    const Text(
                      "Add items to your wishlist to see them here.",
                      style: TextStyle(
                        fontSize: 14,
                        color: kSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: GridView.builder(
                    itemCount: favoriteList.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.64, // match new_all_products.dart
                    ),
                    itemBuilder: (context, index) {
                      final Newproductmodel fav = favoriteList[index];
                      return Stack(
                        children: [
                          NewProductCard(
                            prdouctList: _modelToMap(fav),
                            onAddedToCart: _showAddedToCartPopup,
                            showFavoriteIcon: false, // we handle the icon here to confirm removal
                          ),
                          Positioned(
                            top: 9,
                            right: 9,
                            child: GetBuilder<FavoriteController>(
                              builder: (favorite) {
                                final isFav = favorite.isExist(fav);
                                return GestureDetector(
                                  onTap: () async {
                                    if (isFav) {
                                      _showRemoveConfirmation(context, provider, fav, fav);
                                    } else {
                                      await provider.toggleFavorite(fav, context, silent: true);
                                      _showWishlistPopup(added: true);
                                    }
                                  },
                                  child: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? kredColor : klightblackColor,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
          }),
        ),
      ),
    );
  }

  // Function to display the bottom sheet
  void _showRemoveConfirmation(
      BuildContext context,
      FavoriteController provider,
      Newproductmodel product,
      Newproductmodel favoriteItem) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width;
        final isWide = width > 600;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32.0 : 16.0,
                vertical: isWide ? 24.0 : 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedNetworkImage(
                    imageUrl: (favoriteItem.image != null &&
                            favoriteItem.image!.isNotEmpty)
                        ? ImageHelper.getUrl(favoriteItem.image!)
                        : (favoriteItem.galleryImages != null &&
                                favoriteItem.galleryImages!.isNotEmpty)
                            ? ImageHelper.getUrl(favoriteItem.galleryImages![0])
                            : 'https://via.placeholder.com/150?text=No+Image+Available&fg=FFFFFF', // Fallback if src is null
                    imageBuilder: (context, imageProvider) => Container(
                      height: isWide ? 120 : 100,
                      width: isWide ? 120 : 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          topRight: Radius.circular(8.0),
                        ),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => SizedBox(
                      height: isWide ? 120 : 100,
                      width: isWide ? 120 : 100,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              topRight: Radius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Column(
                      children: [
                        const Text(
                          "No image",
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                        10.0.heightbox,
                        const Icon(Icons.error, color: Colors.red),
                      ],
                    ),
                  ),
                  const Text(
                    "Remove from WishList",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  8.0.heightbox,
                  const Text(
                    "Are you sure you want to remove this item from your Favorites?",
                    textAlign: TextAlign.center,
                  ),
                  15.0.heightbox,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: EdgeInsets.symmetric(
                              vertical: isWide ? 16 : 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: kPrimaryColor),
                              borderRadius: defaultBorderRadious,
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                      10.0.widthbox,
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // Remove silently (no SnackBar), close sheet, then show centered popup
                            await provider.toggleFavorite(product, this.context, silent: true);
                            if (mounted) setState(() {});
                            Navigator.pop(context); // Close the bottom sheet first
                            // Show popup above all (root overlay) after the sheet is closed
                            Future.microtask(() => _showWishlistPopup(added: false));
                          },
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: EdgeInsets.symmetric(
                              vertical: isWide ? 16 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: defaultBorderRadious,
                            ),
                            child: const Center(
                              child: Text(
                                'Yes,Remove',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: kdefwhiteColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
