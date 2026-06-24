import 'dart:convert';
import 'dart:developer';

import 'package:add_to_cart_animation/add_to_cart_animation.dart';
import 'package:animated_read_more_text/animated_read_more_text.dart';
import 'package:graba2z/Controllers/review_controller.dart';
import 'package:graba2z/Utils/image_helper.dart';
import 'package:graba2z/Views/Home/home.dart';
import 'package:graba2z/Views/Product%20Folder/add_review_view.dart';
import 'package:graba2z/Views/Product%20Folder/bulk_purchace_view.dart';
import 'package:graba2z/Views/Product%20Folder/get_coupon.dart';
import 'package:graba2z/Views/Product%20Folder/request_form.dart';
import 'package:graba2z/Views/Product%20Folder/review_show_widget.dart';
import 'package:html/parser.dart' as html_parser;

import 'package:get/get.dart';
import 'package:graba2z/Api/Services/apiservices.dart';
import 'package:graba2z/Configs/config.dart';
import 'package:graba2z/Controllers/addtocart.dart';
import 'package:graba2z/Controllers/favController.dart';
import 'package:graba2z/Controllers/home_controller.dart';
import 'package:graba2z/Utils/appextensions.dart';
import 'package:graba2z/Views/Home/Screens/Cart/cart.dart';
import 'package:graba2z/Views/Product%20Folder/newProduct_card.dart';
import 'package:html/parser.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utils/packages.dart';
import 'package:http/http.dart' as http;
import 'package:graba2z/Views/Payment/tamara_info_screen.dart';
import 'package:graba2z/Views/Payment/tabby_info_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:graba2z/Controllers/review_update_bus.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import '../Home/Screens/Search Screen/searchscreensecond.dart';

const String _homeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 12L12 4L20 12" />
  <path d="M5 12V20H10V15H14V20H19V12" />
</svg>
''';

const String _chat = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-message-circle-icon lucide-message-circle"><path d="M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719"/></svg>
''';

const String _placeholderProductImageUrl =
    'https://i.postimg.cc/SsWYSvq6/noimage.png';

class NewProductDetails extends StatefulWidget {
  List images;
  List specs;
  List reviews;
  String productId;
  String name;
  String brandName;
  String categoryName;
  String categoryId;
  String sku;
  String offerPrice;
  String price;
  String stockStatus;
  String stockCount;
  String description;
  String shortdesc;
  String subcategoryName; // already exists
  List colorVariations;
  List variations;
  List availableModels;

  NewProductDetails({
    super.key,
    required this.images,
    required this.specs,
    required this.reviews,
    required this.productId,
    required this.name,
    required this.brandName,
    required this.categoryName,
    required this.categoryId,
    required this.sku,
    required this.offerPrice,
    required this.price,
    required this.stockStatus,
    this.stockCount = '',
    required this.description,
    required this.shortdesc,
    this.subcategoryName = '', // already has default
    this.colorVariations = const [],
    this.variations = const [],
    this.availableModels = const [],
  });

  @override
  State<NewProductDetails> createState() => _NewProductDetailsState();
}

class _NewProductDetailsState extends State<NewProductDetails>
    with TickerProviderStateMixin {
  GlobalKey<CartIconKey> cartKey = GlobalKey<CartIconKey>();
  late Function(GlobalKey) runAddToCartAnimation;
  var _cartQuantityItems = 0;
  final GlobalKey productImageKey = GlobalKey();
  late String _selectedImageUrl;
  int _currentImageIndex = 0;
  final CarouselSliderController _slider = CarouselSliderController();

  HomeController _homeController = Get.put(HomeController());
  late TabController _tabController;

  final List<String> _tabs = [
    "Description",
    "More Information",
    "Reviews",
  ];

  ReviewController _reviewCont = Get.put(ReviewController());
  int _selectedColorVariationIndex = -1;
  Map<String, dynamic>? _selectedColorData;
  String? _reloadingVariationProductId;
  final Map<String, String> _variationProductLabels = {};
  final Map<String, Map<String, dynamic>> _variationProductCache = {};
  final Set<String> _variationLabelFetchesInFlight = {};
  final Map<String, List<Map<String, String>>> _stableReloadOptions = {};
  bool _colorVariationsLoading = false;
  bool _productOptionsHydrating = false;

  static const Map<String, String> _skuColorCodes = {
    'BLK': 'Black',
    'BLACK': 'Black',
    'WHT': 'White',
    'WHITE': 'White',
    'BLU': 'Blue',
    'BLUE': 'Blue',
    'PNK': 'Pink',
    'PINK': 'Pink',
    'ORG': 'Orange',
    'ORANGE': 'Orange',
    'SIL': 'Silver',
    'SLV': 'Silver',
    'SILVER': 'Silver',
    'GRY': 'Grey',
    'GREY': 'Grey',
    'GRAY': 'Gray',
    'RED': 'Red',
    'GRN': 'Green',
    'GREEN': 'Green',
    'YLW': 'Yellow',
    'YELLOW': 'Yellow',
    'GLD': 'Gold',
    'GOLD': 'Gold',
    'PRP': 'Purple',
    'PURPLE': 'Purple',
    'CLR': 'Clear',
    'CLEAR': 'Clear',
  };

  // API reviews state
  Map<String, dynamic>? _apiReviewStats;
  int _apiCurrentPage = 1;
  bool _apiHasNext = false;
  bool _apiLoading = false;

  // Frequently Bought Together state
  final Map<String, bool> _selectedBundleItems = {};
  List<Map<String, dynamic>> _frequentlyBought = [];
  bool _frequentlyBoughtLoading = false;
  static const int _maxFrequentlyBought = 2; // match website limit
  static const int _defaultPreselectedCount = 2; // match website

  // Category/keyword mapping for accessory suggestions (matches your website exactly)
  static final List<Map<String, dynamic>> _accessoryGroups = [
    {
      'match': [
        'headphone',
        'headphones',
        'headset',
        'earphone',
        'earphones',
        'earbuds',
        'earbud'
      ],
      'excludeMain': [
        'headphone',
        'headphones',
        'headset',
        'earphone',
        'earphones',
        'earbuds',
        'laptop',
        'desktop',
        'mobile',
        'phone',
        'tablet',
        'monitor',
        'printer'
      ],
      'suggestions': [
        {
          'keywords': [
            'headphone',
            'headphones',
            'headset',
            'earphone',
            'earphones',
            'earbuds'
          ],
          'searches': [
            'headphone',
            'headphones',
            'wireless headphone',
            'bluetooth headphone',
            'earbuds'
          ]
        },
        {
          'keywords': ['mouse', 'mice'],
          'searches': ['wireless mouse', 'bluetooth mouse']
        },
        {
          'keywords': ['bag', 'case', 'backpack', 'pouch'],
          'searches': ['laptop bag', 'backpack', 'carrying case', 'travel bag']
        }
      ]
    },
    {
      'match': ['laptop', 'notebook', 'macbook'],
      'excludeMain': [
        'laptop',
        'notebook',
        'macbook',
        'desktop',
        'pc',
        'all in one',
        'monitor',
        'printer',
        'headphone',
        'mobile'
      ],
      'suggestions': [
        {
          'keywords': ['mouse', 'mice'],
          'searches': ['wireless mouse', 'bluetooth mouse', 'laptop mouse']
        },
        {
          'keywords': ['keyboard'],
          'searches': [
            'wireless keyboard',
            'bluetooth keyboard',
            'laptop keyboard'
          ]
        },
        {
          'keywords': ['bag', 'case', 'backpack', 'sleeve'],
          'searches': [
            'laptop bag',
            'laptop backpack',
            'laptop case',
            'laptop sleeve'
          ]
        },
        {
          'keywords': ['hub', 'adapter', 'dongle'],
          'searches': ['usb hub', 'usb-c hub', 'hdmi adapter', 'type-c adapter']
        },
        {
          'keywords': ['stand', 'holder'],
          'searches': ['laptop stand', 'laptop holder']
        },
        {
          'keywords': ['cooler', 'cooling', 'pad'],
          'searches': ['laptop cooling pad', 'cooling stand']
        },
        {
          'keywords': ['headphone', 'headset', 'earphone', 'earbuds'],
          'searches': ['wireless headphones', 'bluetooth headset', 'earbuds']
        },
        {
          'keywords': ['ssd', 'ram', 'memory'],
          'searches': ['external ssd', 'laptop ram', 'memory upgrade']
        }
      ]
    },
    {
      'match': [
        'desktop',
        'pc',
        'computer',
        'workstation',
        'all in one',
        'aio'
      ],
      'excludeMain': [
        'desktop',
        'pc',
        'computer',
        'workstation',
        'laptop',
        'notebook',
        'macbook',
        'monitor',
        'printer',
        'mobile'
      ],
      'suggestions': [
        {
          'keywords': ['mouse', 'mice'],
          'searches': ['wired mouse', 'wireless mouse', 'gaming mouse']
        },
        {
          'keywords': ['keyboard'],
          'searches': [
            'wired keyboard',
            'wireless keyboard',
            'mechanical keyboard'
          ]
        },
        {
          'keywords': ['speaker', 'speakers'],
          'searches': ['desktop speakers', 'computer speakers']
        },
        {
          'keywords': ['webcam', 'camera'],
          'searches': ['usb webcam', 'hd webcam']
        },
        {
          'keywords': ['headphone', 'headset'],
          'searches': ['wired headset', 'usb headset', 'gaming headset']
        },
        {
          'keywords': ['ssd', 'hdd', 'storage'],
          'searches': ['internal ssd', 'external hdd', 'storage']
        },
        {
          'keywords': ['ram', 'memory'],
          'searches': ['desktop ram', 'ddr4 ram', 'memory']
        }
      ]
    },
    {
      'match': ['monitor', 'display', 'screen'],
      'excludeMain': [
        'monitor',
        'display',
        'laptop',
        'desktop',
        'pc',
        'printer',
        'mobile',
        'tablet'
      ],
      'suggestions': [
        {
          'keywords': ['cables'],
          'searches': ['cables']
        },
        {
          'keywords': ['mouse', 'mice'],
          'searches': ['wireless mouse', 'gaming mouse']
        },
      ]
    },
    {
      'match': [
        'printer',
        'printers',
        'copier',
        'scanner',
        'scanners',
        'multifunction',
        'mfp',
        'inkjet',
        'laser'
      ],
      'excludeMain': [
        'printer',
        'printers',
        'copier',
        'scanner',
        'laptop',
        'desktop',
        'monitor',
        'networking',
        'router',
        'switch',
        'access point',
        'mobile'
      ],
      'suggestions': [
        {
          'keywords': ['paper', 'a4', 'a3'],
          'searches': ['a4 paper', 'printer paper', 'copy paper']
        },
        {
          'keywords': ['ink', 'toner', 'cartridge', 'cartridges'],
          'searches': [
            'printer ink',
            'toner cartridge',
            'ink cartridge',
            'toner'
          ]
        },
        {
          'keywords': ['usb', 'cable', 'power'],
          'searches': ['usb printer cable', 'printer cable', 'power cable']
        }
      ]
    },
    {
      'match': ['mobile', 'phone', 'smartphone', 'iphone', 'samsung'],
      'excludeMain': [
        'mobile',
        'phone',
        'smartphone',
        'iphone',
        'samsung',
        'tablet',
        'laptop',
        'desktop',
        'monitor'
      ],
      'suggestions': [
        {
          'keywords': ['case', 'cover'],
          'searches': ['phone case', 'mobile cover', 'protective case']
        },
        {
          'keywords': ['screen', 'protector', 'glass'],
          'searches': ['screen protector', 'tempered glass']
        },
        {
          'keywords': ['charger', 'adapter'],
          'searches': ['fast charger', 'phone charger', 'usb charger']
        },
        {
          'keywords': ['cable', 'usb', 'type-c'],
          'searches': ['charging cable', 'usb cable', 'type-c cable']
        },
        {
          'keywords': ['power bank', 'powerbank', 'battery'],
          'searches': ['power bank', 'portable charger']
        },
        {
          'keywords': ['earphone', 'earbuds', 'headphone'],
          'searches': ['wireless earbuds', 'bluetooth earphones']
        },
        {
          'keywords': ['holder', 'stand', 'mount'],
          'searches': ['phone holder', 'car mount', 'phone stand']
        }
      ]
    }
  ];

  // Fallback keywords when no specific group matches
  static final List<String> _fallbackKeywords = [
    'mouse',
    'keyboard',
    'headphone',
    'headset',
    'earbuds',
    'earphone',
    'bag',
    'case',
    'hdmi',
    'cable',
    'ethernet',
    'router',
    'switch',
    'hub',
    'adapter',
    'ssd',
    'ram',
    'memory',
    'stand',
    'holder'
  ];

  // NEW: Generic fallback search terms (laptop-style for all categories)
  static final List<String> _genericFallbackSearches = [
    'wireless mouse',
    'bluetooth mouse',
    'wireless keyboard',
    'bluetooth keyboard',
    'usb hub',
    'usb-c hub',
    'hdmi cable',
    'laptop bag',
    'laptop stand',
    'screen cleaner',
    'headphones',
    'earbuds',
  ];

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  double _basePrice(Map p) {
    final offer = _toDouble(p['offerPrice']);
    final price = _toDouble(p['price']);
    return (offer > 0 && offer < price) ? offer : price;
  }

  double _discounted(double price, int percent) =>
      (price * (100 - percent)) / 100.0;

  String _fmt(double v) => 'AED ${v.toStringAsFixed(2)}';

  String _idOf(Map p) => (p['_id'] ?? '').toString();

  String _imgOf(Map p) {
    final img = p['image']?.toString();
    if (img != null && img.isNotEmpty) return img;
    final g = p['galleryImages'];
    if (g is List && g.isNotEmpty && g.first != null) return g.first.toString();
    return _placeholderProductImageUrl;
  }

  Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  String _firstNonEmpty(Map<String, dynamic> data, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return fallback;
  }

  List _listFromProduct(Map<String, dynamic> product, List<String> keys) {
    for (final key in keys) {
      final value = product[key];
      if (value is List) return List<dynamic>.from(value);
    }
    return const [];
  }

  void _addImageValue(List<String> images, dynamic raw) {
    if (raw == null) return;
    if (raw is List) {
      for (final item in raw) {
        _addImageValue(images, item);
      }
      return;
    }
    if (raw is Map) {
      final map = _asStringMap(raw);
      _addImageValue(
          images, map['url'] ?? map['src'] ?? map['path'] ?? map['image']);
      return;
    }
    final value = raw.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return;
    if (!images.contains(value)) images.add(value);
  }

  List<String> _imagesFromProductMap(Map<String, dynamic> product,
      {List fallback = const []}) {
    final images = <String>[];

    for (final key in const [
      'image',
      'mainImage',
      'thumbnail',
      'primaryImage',
      'galleryImages',
      'images',
      'gallery',
      'imageUrls',
      'productImages',
    ]) {
      _addImageValue(images, product[key]);
    }

    if (images.isEmpty) {
      for (final image in fallback) {
        _addImageValue(images, image);
      }
    }

    if (images.isEmpty) images.add(_placeholderProductImageUrl);
    return images;
  }

  String _stockStatusFromMap(Map<String, dynamic> product,
      {String fallback = 'Unknown'}) {
    final countedStock = product['countInStock'];
    if (countedStock != null) {
      return _toDouble(countedStock) > 0 ? 'In Stock' : 'Out of Stock';
    }

    final explicit = _firstNonEmpty(
      product,
      const ['stockStatus', 'availability', 'status'],
    );
    if (explicit.isNotEmpty) return explicit;

    final stock = product['stock'] ??
        product['stockCount'] ??
        product['countInStock'] ??
        product['quantity'] ??
        product['availableQuantity'] ??
        product['qty'];
    final count = _toDouble(stock);
    if (stock != null) return count > 0 ? 'In Stock' : 'Out of Stock';
    return fallback;
  }

  String _stockCountFromMap(Map<String, dynamic> product,
      {String fallback = ''}) {
    return _firstNonEmpty(
      product,
      const [
        'stock',
        'stockCount',
        'countInStock',
        'quantity',
        'availableQuantity',
        'qty'
      ],
      fallback: fallback,
    );
  }

  String _brandNameFromProduct(Map<String, dynamic> product,
      {String fallback = ''}) {
    final brand = product['brand'] ?? product['brandName'];
    if (brand is Map) {
      return _firstNonEmpty(_asStringMap(brand), const ['name', 'title'],
          fallback: fallback);
    }
    if (brand is String && brand.trim().isNotEmpty) return brand.trim();
    return fallback;
  }

  String _categoryNameFromProduct(Map<String, dynamic> product,
      {String fallback = ''}) {
    final category = product['parentCategory'] ??
        product['category'] ??
        product['categoryName'];
    if (category is Map) {
      return _firstNonEmpty(_asStringMap(category), const ['name', 'title'],
          fallback: fallback);
    }
    if (category is String && category.trim().isNotEmpty) {
      return category.trim();
    }
    return fallback;
  }

  String _categoryIdFromProduct(Map<String, dynamic> product,
      {String fallback = ''}) {
    final category = product['parentCategory'] ??
        product['category'] ??
        product['categoryId'];
    if (category is Map) {
      return _firstNonEmpty(_asStringMap(category), const ['_id', 'id'],
          fallback: fallback);
    }
    if (category is String && category.trim().isNotEmpty) {
      return category.trim();
    }
    return fallback;
  }

  String _subcategoryNameFromProduct(Map<String, dynamic> product,
      {String fallback = ''}) {
    final subcategory = product['subcategory'] ??
        product['subCategory'] ??
        product['childCategory'];
    if (subcategory is Map) {
      return _firstNonEmpty(_asStringMap(subcategory), const ['name', 'title'],
          fallback: fallback);
    }
    if (subcategory is String && subcategory.trim().isNotEmpty) {
      return subcategory.trim();
    }
    return fallback;
  }

  String _optionLabel(dynamic option, List<String> preferredKeys) {
    final direct = _directOptionLabel(option, preferredKeys);
    return direct.isNotEmpty ? direct : 'Option';
  }

  String _directOptionLabel(dynamic option, List<String> preferredKeys) {
    final map = _asStringMap(option);
    for (final key in preferredKeys) {
      final value = map[key];
      if (value == null) continue;
      if (value is Map) {
        final nested = _firstNonEmpty(
          _asStringMap(value),
          const ['variationText', 'name', 'title', 'label', 'value'],
        );
        if (_isMeaningfulOptionLabel(nested)) return nested;
      } else {
        final text = value.toString().trim();
        if (_isMeaningfulOptionLabel(text)) return text;
      }
    }
    final fallback = _firstNonEmpty(
      map,
      const [
        'variationText',
        'variantText',
        'optionText',
        'name',
        'label',
        'title',
        'value',
        'storage',
        'capacity',
        'memory',
        'model',
        'sku',
      ],
    );
    return _isMeaningfulOptionLabel(fallback) ? fallback : '';
  }

  bool _isMeaningfulOptionLabel(String value) {
    final text = value.trim();
    if (text.isEmpty) return false;
    final lower = text.toLowerCase();
    return lower != 'null' &&
        lower != 'option' &&
        lower != 'select option' &&
        lower != 'available option';
  }

  String _capacityLabelFromText(String text) {
    final matches = RegExp(r'\b\d+\s*(?:GB|TB)\b', caseSensitive: false)
        .allMatches(text)
        .map((m) => m.group(0)!.replaceAll(RegExp(r'\s+'), '').toUpperCase())
        .toList();

    final unique = <String>[];
    for (final match in matches) {
      if (!unique.contains(match)) unique.add(match);
    }

    if (unique.length >= 2) return '${unique[0]}-${unique[1]}';
    if (unique.length == 1) return unique.first;
    return '';
  }

  String _labelFromProductSummary(Map<String, dynamic> product) {
    final direct = _directOptionLabel(
      product,
      const [
        'variationText',
        'variantText',
        'optionText',
        'storage',
        'capacity',
        'memory',
        'model',
        'name',
        'label',
        'value',
      ],
    );
    final capacityFromDirect = _capacityLabelFromText(direct);
    if (capacityFromDirect.isNotEmpty) return capacityFromDirect;
    if (_isMeaningfulOptionLabel(direct) && direct.length <= 24) return direct;

    final skuCapacity =
        _capacityLabelFromText((product['sku'] ?? '').toString());
    if (skuCapacity.isNotEmpty) return skuCapacity;

    final nameCapacity =
        _capacityLabelFromText((product['name'] ?? '').toString());
    if (nameCapacity.isNotEmpty) return nameCapacity;

    final sku = (product['sku'] ?? '').toString().trim();
    if (_isMeaningfulOptionLabel(sku)) return sku;
    return '';
  }

  String _currentReloadOptionLabel() {
    final skuCapacity = _capacityLabelFromText(widget.sku);
    if (skuCapacity.isNotEmpty) return skuCapacity;

    final nameCapacity = _capacityLabelFromText(widget.name);
    if (nameCapacity.isNotEmpty) return nameCapacity;

    return widget.sku.isNotEmpty ? widget.sku : 'Current Option';
  }

  String _reloadOptionLabel(dynamic option, List<String> labelKeys) {
    final direct = _directOptionLabel(option, labelKeys);
    final directCapacity = _capacityLabelFromText(direct);
    if (directCapacity.isNotEmpty) return directCapacity;
    if (_isMeaningfulOptionLabel(direct) && direct.length <= 24) return direct;

    final map = _asStringMap(option);
    for (final key in const ['product', 'linkedProduct', 'variantProduct']) {
      final nested = map[key];
      if (nested is Map) {
        final label = _labelFromProductSummary(_asStringMap(nested));
        if (label.isNotEmpty) return label;
      }
    }

    final productId = _productIdFromOption(option);
    final cached = _variationProductLabels[productId];
    if (cached != null && cached.isNotEmpty) return cached;

    final fallback = _labelFromProductSummary(map);
    if (fallback.isNotEmpty) return fallback;
    return 'Loading...';
  }

  String _colorLabelFromSku(String sku) {
    final parts = sku.split('-');
    if (parts.isEmpty) return '';
    final last = parts.last.trim().toUpperCase();
    return _skuColorCodes[last] ?? '';
  }

  String _colorLabelFromName(String name) {
    final lower = name.toLowerCase();
    for (final label in _skuColorCodes.values.toSet()) {
      final pattern = RegExp(
        r'(^|[^a-z])' + RegExp.escape(label.toLowerCase()) + r'([^a-z]|$)',
      );
      if (pattern.hasMatch(lower)) return label;
    }
    return '';
  }

  String _colorLabelFromProduct(Map<String, dynamic> product) {
    final direct = _firstNonEmpty(product, const [
      'currentProductColor',
      'color',
      'colour',
      'colorName',
      'colourName',
    ]);
    if (_isMeaningfulOptionLabel(direct)) return direct;

    final skuLabel = _colorLabelFromSku((product['sku'] ?? '').toString());
    if (skuLabel.isNotEmpty) return skuLabel;

    return _colorLabelFromName((product['name'] ?? '').toString());
  }

  String _colorSearchPrefixFromSku(String sku) {
    final parts =
        sku.split('-').where((part) => part.trim().isNotEmpty).toList();
    if (parts.length < 2) return '';

    final last = parts.last.trim().toUpperCase();
    if (!_skuColorCodes.containsKey(last)) return '';

    return parts.take(parts.length - 1).join('-');
  }

  int _colorSortIndex(String color) {
    const order = [
      'Pink',
      'Blue',
      'Orange',
      'Silver',
      'Black',
      'White',
      'Grey',
      'Gray',
      'Red',
      'Green',
      'Yellow',
      'Gold',
      'Purple',
      'Clear',
    ];
    final index = order.indexWhere(
      (item) => item.toLowerCase() == color.toLowerCase(),
    );
    return index == -1 ? order.length : index;
  }

  List<Map<String, String>> _stableOptionsForGroup(
    String groupKey,
    List options,
    List<String> labelKeys,
  ) {
    final existing = _stableReloadOptions[groupKey];
    if (existing != null && existing.isNotEmpty) {
      final hasCurrent =
          existing.any((option) => option['productId'] == widget.productId);
      if (!hasCurrent && widget.productId.isNotEmpty) {
        existing.add({
          'productId': widget.productId,
          'label': _currentReloadOptionLabel(),
        });
      }
      return existing;
    }

    final seenProductIds = <String>{};
    final stable = <Map<String, String>>[];

    if (widget.productId.isNotEmpty) {
      _variationProductCache.putIfAbsent(
        widget.productId,
        () => _currentProductSnapshot(),
      );
      stable.add({
        'productId': widget.productId,
        'label': _currentReloadOptionLabel(),
      });
      seenProductIds.add(widget.productId);
    }

    for (final option in options) {
      final productId = _productIdFromOption(option);
      if (productId.isNotEmpty && seenProductIds.contains(productId)) continue;

      final label = _reloadOptionLabel(option, labelKeys);
      stable.add({
        'productId': productId,
        'label': label == 'Loading...' ? 'Option' : label,
      });
      if (productId.isNotEmpty) seenProductIds.add(productId);
    }

    _stableReloadOptions[groupKey] = stable;
    return stable;
  }

  String _productIdFromOption(dynamic option) {
    final map = _asStringMap(option);
    for (final key in const [
      'productId',
      'linkedProductId',
      'newProductId',
      'product_id',
      'variantProductId',
      'targetProductId',
    ]) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }

    for (final key in const ['product', 'linkedProduct', 'variantProduct']) {
      final value = map[key];
      if (value is Map) {
        final id = _firstNonEmpty(_asStringMap(value), const ['_id', 'id']);
        if (id.isNotEmpty) return id;
      } else if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
      }
    }

    return _firstNonEmpty(map, const ['_id', 'id']);
  }

  bool _isOutOfStock(String status) {
    return status.toLowerCase().trim() == 'out of stock';
  }

  Map<String, dynamic> _productPayloadFromResponse(dynamic decoded) {
    return decoded is Map
        ? (decoded['data'] is Map
            ? _asStringMap(decoded['data'])
            : decoded['product'] is Map
                ? _asStringMap(decoded['product'])
                : _asStringMap(decoded))
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _fetchProductPayload(String productId) async {
    final response = await http
        .get(Uri.parse('${Configss.baseUrl}/api/mobile/products/$productId'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load product: ${response.statusCode}');
    }

    final product = _productPayloadFromResponse(json.decode(response.body));
    if (product.isEmpty) throw Exception('Unexpected product payload');
    return product;
  }

  Map<String, dynamic> _currentProductSnapshot() {
    return {
      '_id': widget.productId,
      'name': widget.name,
      'brandName': widget.brandName,
      'categoryName': widget.categoryName,
      'categoryId': widget.categoryId,
      'subCategory': widget.subcategoryName,
      'sku': widget.sku,
      'offerPrice': widget.offerPrice,
      'price': widget.price,
      'stockStatus': widget.stockStatus,
      'stockCount': widget.stockCount,
      'currentProductColor': _colorLabelFromSku(widget.sku),
      'description': widget.description,
      'shortDescription': widget.shortdesc,
      'galleryImages': List<dynamic>.from(widget.images),
      'specifications': List<dynamic>.from(widget.specs),
      'reviews': List<dynamic>.from(widget.reviews),
      'colorVariations': List<dynamic>.from(widget.colorVariations),
      'variations': List<dynamic>.from(widget.variations),
      'availableModels': List<dynamic>.from(widget.availableModels),
    };
  }

  void _syncImageSelection() {
    _currentImageIndex = 0;
    _selectedImageUrl = widget.images.isNotEmpty
        ? ImageHelper.getUrl(_rawImageAt(0))
        : _placeholderProductImageUrl;
    try {
      _slider.jumpToPage(0);
    } catch (_) {}
  }

  void _applyProductPayload(Map<String, dynamic> product,
      {String? forcedProductId}) {
    widget.productId = forcedProductId?.isNotEmpty == true
        ? forcedProductId!
        : _firstNonEmpty(product, const ['_id', 'id'],
            fallback: widget.productId);
    widget.name =
        _firstNonEmpty(product, const ['name', 'title'], fallback: widget.name);
    widget.brandName =
        _brandNameFromProduct(product, fallback: widget.brandName);
    widget.categoryName =
        _categoryNameFromProduct(product, fallback: widget.categoryName);
    widget.categoryId =
        _categoryIdFromProduct(product, fallback: widget.categoryId);
    widget.subcategoryName =
        _subcategoryNameFromProduct(product, fallback: widget.subcategoryName);
    widget.sku =
        _firstNonEmpty(product, const ['sku', 'model'], fallback: widget.sku);
    widget.offerPrice = _firstNonEmpty(
      product,
      const ['offerPrice', 'salePrice', 'discountPrice'],
      fallback: widget.offerPrice,
    );
    widget.price = _firstNonEmpty(
      product,
      const ['price', 'regularPrice', 'mrp'],
      fallback: widget.price,
    );
    widget.stockStatus =
        _stockStatusFromMap(product, fallback: widget.stockStatus);
    widget.stockCount =
        _stockCountFromMap(product, fallback: widget.stockCount);
    widget.description = _firstNonEmpty(
      product,
      const ['description', 'longDescription'],
      fallback: widget.description,
    );
    widget.shortdesc = _firstNonEmpty(
      product,
      const ['shortDescription', 'shortdesc', 'shortDesc'],
      fallback: widget.shortdesc,
    );
    widget.images = _imagesFromProductMap(product, fallback: widget.images);
    widget.specs = _listFromProduct(product, const ['specifications', 'specs']);
    widget.reviews =
        _listFromProduct(product, const ['reviews', 'productReviews']);
    widget.colorVariations =
        _listFromProduct(product, const ['colorVariations', 'colors']);
    widget.variations =
        _listFromProduct(product, const ['variations', 'storageVariations']);
    widget.availableModels =
        _listFromProduct(product, const ['availableModels', 'models']);
    _selectedColorVariationIndex = -1;
    _selectedColorData = null;
    _syncImageSelection();
  }

  void _loadSideDataForCurrentProduct() {
    if (widget.categoryId.isNotEmpty) {
      _homeController.getRelatedProducts(widget.categoryId);
    }
    _fetchReviews(page: 1);
    _fetchFrequentlyBought();
    _hydrateMissingProductOptions();
    _preloadVariationOptionLabels();
    _fetchSiblingColorVariationsIfNeeded();

    _reviewCont.reviews.value = List<dynamic>.from(widget.reviews);
  }

  Future<void> _hydrateMissingProductOptions() async {
    if (_productOptionsHydrating || widget.productId.isEmpty) return;
    if (widget.colorVariations.isNotEmpty &&
        widget.variations.isNotEmpty &&
        widget.availableModels.isNotEmpty) {
      return;
    }

    _productOptionsHydrating = true;
    final productIdAtStart = widget.productId;
    try {
      final product = await _fetchProductPayload(productIdAtStart);
      if (!mounted || widget.productId != productIdAtStart) return;

      final colorVariations =
          _listFromProduct(product, const ['colorVariations', 'colors']);
      final variations =
          _listFromProduct(product, const ['variations', 'storageVariations']);
      final availableModels =
          _listFromProduct(product, const ['availableModels', 'models']);

      setState(() {
        if (widget.colorVariations.isEmpty && colorVariations.isNotEmpty) {
          widget.colorVariations = colorVariations;
        }
        if (widget.variations.isEmpty && variations.isNotEmpty) {
          widget.variations = variations;
        }
        if (widget.availableModels.isEmpty && availableModels.isNotEmpty) {
          widget.availableModels = availableModels;
        }
        if (widget.stockCount.isEmpty) {
          widget.stockCount =
              _stockCountFromMap(product, fallback: widget.stockCount);
        }
      });
    } catch (e) {
      log('Error hydrating product options: $e');
    } finally {
      _productOptionsHydrating = false;
    }
  }

  Future<void> _fetchSiblingColorVariationsIfNeeded() async {
    if (_colorVariationsLoading || widget.colorVariations.isNotEmpty) return;

    final skuPrefix = _colorSearchPrefixFromSku(widget.sku);
    if (skuPrefix.isEmpty) return;

    setState(() => _colorVariationsLoading = true);
    try {
      final url =
          '${Configss.baseUrl}/api/mobile/products?search=${Uri.encodeQueryComponent(skuPrefix)}&limit=30';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      final rawItems = decoded is Map && decoded['data'] is List
          ? List<dynamic>.from(decoded['data'])
          : decoded is Map && decoded['products'] is List
              ? List<dynamic>.from(decoded['products'])
              : <dynamic>[];

      final colorProducts = <Map<String, dynamic>>[];
      final seenProductIds = <String>{};

      for (final raw in rawItems) {
        final product = _asStringMap(raw);
        final id = _firstNonEmpty(product, const ['_id', 'id']);
        final sku = (product['sku'] ?? '').toString();
        if (id.isEmpty || seenProductIds.contains(id)) continue;
        if (!sku.toUpperCase().startsWith('${skuPrefix.toUpperCase()}-')) {
          continue;
        }

        final colorLabel = _colorLabelFromProduct(product);
        if (colorLabel.isEmpty) continue;

        seenProductIds.add(id);
        colorProducts.add({
          ...product,
          'productId': id,
          'colorName': colorLabel,
          'color': colorLabel,
        });
      }

      if (colorProducts.length < 2) return;

      colorProducts.sort((a, b) {
        final byColor = _colorSortIndex((a['colorName'] ?? '').toString())
            .compareTo(_colorSortIndex((b['colorName'] ?? '').toString()));
        if (byColor != 0) return byColor;
        return (a['sku'] ?? '')
            .toString()
            .compareTo((b['sku'] ?? '').toString());
      });

      if (!mounted) return;
      setState(() {
        widget.colorVariations = colorProducts;
        final currentIndex = colorProducts.indexWhere(
          (product) =>
              (product['productId'] ?? '').toString() == widget.productId,
        );
        _selectedColorVariationIndex = currentIndex;
      });
    } catch (e) {
      log('Error fetching sibling color variations: $e');
    } finally {
      if (mounted) setState(() => _colorVariationsLoading = false);
    }
  }

  Future<void> _preloadVariationOptionLabels() async {
    final options = <dynamic>[
      ...widget.variations,
      ...widget.availableModels,
    ];

    for (final option in options) {
      final productId = _productIdFromOption(option);
      if (productId.isEmpty ||
          productId == widget.productId ||
          _variationProductCache.containsKey(productId) ||
          _variationLabelFetchesInFlight.contains(productId)) {
        continue;
      }

      final direct = _reloadOptionLabel(option, const [
        'variationText',
        'variantText',
        'optionText',
        'storage',
        'capacity',
        'memory',
        'model',
        'name',
        'label',
        'value',
      ]);
      if (direct != 'Loading...') {
        _variationProductLabels[productId] = direct;
      }

      _variationLabelFetchesInFlight.add(productId);
      try {
        final product = await _fetchProductPayload(productId);
        _variationProductCache[productId] = product;
        final label = _labelFromProductSummary(product);
        if (label.isNotEmpty) {
          _variationProductLabels[productId] = label;
        }
      } catch (e) {
        log('Error preloading variation label $productId: $e');
      } finally {
        _variationLabelFetchesInFlight.remove(productId);
      }
    }

    if (mounted) setState(() {});
  }

  void _applyColorVariation(dynamic option, int index) {
    final variation = _asStringMap(option);
    if (variation.isEmpty) return;

    setState(() {
      _selectedColorVariationIndex = index;
      _selectedColorData = Map<String, dynamic>.from(variation);
      widget.images = _imagesFromProductMap(variation, fallback: widget.images);
      widget.sku = _firstNonEmpty(variation, const ['sku', 'model'],
          fallback: widget.sku);
      widget.offerPrice = _firstNonEmpty(
        variation,
        const ['offerPrice', 'salePrice', 'discountPrice'],
        fallback: widget.offerPrice,
      );
      widget.price = _firstNonEmpty(
        variation,
        const ['price', 'regularPrice', 'mrp'],
        fallback: widget.price,
      );
      widget.stockStatus =
          _stockStatusFromMap(variation, fallback: widget.stockStatus);
      widget.stockCount =
          _stockCountFromMap(variation, fallback: widget.stockCount);

      _syncImageSelection();
    });
  }

  Map<String, dynamic>? _selectedColorCartData() {
    if (_selectedColorVariationIndex < 0 || _selectedColorData == null) {
      return null;
    }

    final color = _optionLabel(
      _selectedColorData,
      const ['color', 'colour', 'colorName', 'colourName', 'name', 'label'],
    );
    final image = _imagesFromProductMap(_selectedColorData!).first;

    return {
      'color': color == 'Option' ? '' : color,
      'image': image,
      'galleryImages': _listFromProduct(
        _selectedColorData!,
        const ['galleryImages', 'images', 'gallery', 'productImages'],
      ),
      'price': _toDouble(_selectedColorData!['price']),
      'offerPrice': _toDouble(_selectedColorData!['offerPrice']),
      'sku': (_selectedColorData!['sku'] ?? '').toString(),
      'countInStock': _toDouble(
        _selectedColorData!['countInStock'] ??
            _selectedColorData!['stockCount'] ??
            _selectedColorData!['stock'],
      ).toInt(),
    };
  }

  Future<void> _reloadProductById(String productId) async {
    if (productId.isEmpty || productId == widget.productId) return;

    final cachedProduct = _variationProductCache[productId];
    if (cachedProduct != null && cachedProduct.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _applyProductPayload(cachedProduct, forcedProductId: productId);
        _reloadingVariationProductId = null;
      });
      _loadSideDataForCurrentProduct();
      return;
    }

    setState(() => _reloadingVariationProductId = productId);

    try {
      final product = await _fetchProductPayload(productId);
      _variationProductCache[productId] = product;
      if (!mounted) return;

      setState(() {
        _applyProductPayload(product, forcedProductId: productId);
        _reloadingVariationProductId = null;
      });
      _loadSideDataForCurrentProduct();
    } catch (e) {
      log('Error loading variation product $productId: $e');
      if (!mounted) return;
      setState(() => _reloadingVariationProductId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load selected product')),
      );
    }
  }

  String _rawImageAt(int index) {
    if (index < 0 || index >= widget.images.length) {
      return _placeholderProductImageUrl;
    }

    final raw = widget.images[index];
    if (raw == null) return _placeholderProductImageUrl;

    final value = raw.toString().trim();
    return value.isEmpty ? _placeholderProductImageUrl : value;
  }

  List<String> _imageUrlsForViewer() {
    final urls = <String>[];

    for (final image in widget.images) {
      if (image == null) continue;
      final raw = image.toString().trim();
      if (raw.isEmpty) continue;
      urls.add(ImageHelper.getUrl(raw));
    }

    if (urls.isEmpty) {
      urls.add(_placeholderProductImageUrl);
    }

    return urls;
  }

  void _openImageViewer({required int initialIndex}) {
    final imageUrls = _imageUrlsForViewer();
    final safeIndex = initialIndex.clamp(0, imageUrls.length - 1);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) {
          return _ProductImageViewer(
            imageUrls: imageUrls,
            initialIndex: safeIndex,
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    log('NewProductDetails initState START ------------------------');
    log('NewProductDetails initState: Received Product ID: ${widget.productId}');
    log('NewProductDetails initState: Received Name: ${widget.name}');
    log('NewProductDetails initState: Received Brand Name: "${widget.brandName}"');
    log('NewProductDetails initState: Received Category Name: "${widget.categoryName}"');

    // If brand name is empty, try to fetch from product API
    if (widget.brandName.isEmpty && widget.productId.isNotEmpty) {
      log('🔄 Brand name is empty, fetching from product API...');
      _fetchBrandName();
    }

    log('NewProductDetails initState: Received Images count: ${widget.images.length}');
    if (widget.images.isNotEmpty) {
      log('NewProductDetails initState: First image: ${widget.images.first}');
    } else {
      log('NewProductDetails initState: Received Images list is EMPTY');
    }
    log('NewProductDetails initState: Received Price: ${widget.price}');
    log('NewProductDetails initState: Received OfferPrice: ${widget.offerPrice}');
    log('NewProductDetails initState: Received Category ID: ${widget.categoryId}');
    log('NewProductDetails initState: Received stockStatus: ${widget.stockStatus}');

    _tabController = TabController(length: _tabs.length, vsync: this);

    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _selectedImageUrl = widget.images.isNotEmpty
        ? ImageHelper.getUrl(_rawImageAt(0))
        : _placeholderProductImageUrl;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Run all API calls in parallel - no need to wait, just trigger them
        _loadSideDataForCurrentProduct();
      }
    });

    log('NewProductDetails initState END ------------------------');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Fetch brand name from product API if not provided
  Future<void> _fetchBrandName() async {
    try {
      if (widget.productId.isEmpty) return;

      // Timeout after 5 seconds to prevent hanging
      final response = await http
          .get(
        Uri.parse('${Configss.baseUrl}/api/products/${widget.productId}'),
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          log('❌ Brand fetch timeout');
          throw TimeoutException('Brand fetch took too long');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('✅ Fetched product from API: ${data['name']}');

        String fetchedBrandName = '';
        if (data['brand'] is Map) {
          fetchedBrandName = (data['brand']['name'] ?? '').toString();
        }

        if (fetchedBrandName.isNotEmpty && mounted) {
          log('✅ Got brand name from API: $fetchedBrandName');
          setState(() {
            widget.brandName = fetchedBrandName;
          });
        }
      } else {
        log('❌ Failed to fetch product: ${response.statusCode}');
      }
    } on TimeoutException {
      log('⏱️ Brand fetch timed out - using N/A');
    } catch (e) {
      log('❌ Error fetching brand name: $e');
    }
  }

  Future<void> _fetchReviews({int page = 1}) async {
    if (widget.productId.isEmpty) return;
    if (mounted) {
      setState(() => _apiLoading = true);
    }

    try {
      final endpoint =
          Configss.getReview.replaceFirst(':productId', widget.productId);
      final url = '$endpoint?page=$page';
      log('Fetching reviews: $url');

      // Add timeout to prevent hanging
      final res = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Reviews fetch timed out');
        },
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body =
            json.decode(res.body) as Map<String, dynamic>;
        final List<dynamic> newReviewsRaw =
            (body['reviews'] as List?) ?? const [];
        final List<Map<String, dynamic>> newReviews = newReviewsRaw
            .where((e) => e is Map)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final Map<String, dynamic>? stats = body['stats'] is Map
            ? Map<String, dynamic>.from(body['stats'])
            : null;
        final Map<String, dynamic> pagination = body['pagination'] is Map
            ? Map<String, dynamic>.from(body['pagination'])
            : {};

        if (!mounted) return;
        setState(() {
          if (page == 1) {
            _reviewCont.reviews.value = newReviews;
          } else {
            _reviewCont.reviews.addAll(newReviews);
          }
          _apiReviewStats = stats;
          _apiCurrentPage = (pagination['currentPage'] as int?) ?? page;
          _apiHasNext = (pagination['hasNext'] as bool?) ?? false;
        });
      } else {
        log('Failed to fetch reviews. Status: ${res.statusCode}');
      }
    } on TimeoutException {
      log('⏱️ Reviews fetch timed out');
    } catch (e, st) {
      log('Error fetching reviews: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _apiLoading = false);
      }
    }
  }

  bool _includesAny(String text, List<String> keywords) {
    final lower = text.toLowerCase();
    return keywords.any((k) => lower.contains(k.toLowerCase()));
  }

  bool _isMainProductType(String text, List<String> excludeWords) {
    final lower = text.toLowerCase();

    for (final word in excludeWords) {
      final w = word.toLowerCase();

      // Exact match
      if (lower == w) return true;

      // Word boundary match
      final pattern = RegExp(r'\b' + RegExp.escape(w) + r'\b');
      if (pattern.hasMatch(lower)) return true;

      // Common patterns
      if (w == 'laptop' &&
          (lower.contains('laptop') || lower.contains('notebook'))) return true;
      if (w == 'desktop' &&
          (lower.contains('desktop') ||
              lower.contains(' pc') ||
              lower.contains('workstation'))) return true;
      if (w == 'monitor' && lower.contains('monitor')) return true;
      if (w == 'printer' &&
          (lower.contains('printer') || lower.contains('copier'))) return true;
      if (w == 'mobile' &&
          (lower.contains('mobile') ||
              lower.contains('phone') ||
              lower.contains('smartphone'))) return true;
    }

    return false;
  }

  Map<String, dynamic>? _pickGroupByMatch(
      String productName, String categoryName) {
    final subcategoryName = widget.subcategoryName;
    final combined =
        '$productName $categoryName $subcategoryName'.toLowerCase();

    for (final group in _accessoryGroups) {
      final matches = (group['match'] as List).cast<String>();
      if (_includesAny(combined, matches)) {
        return group;
      }
    }
    return null;
  }

  List<String> _extractGroupFallbackKeywords(Map<String, dynamic>? group) {
    if (group == null) return const [];

    final suggestions =
        (group['suggestions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final keywords = <String>{};

    for (final suggestion in suggestions) {
      final kws = (suggestion['keywords'] as List?)?.cast<String>() ?? [];
      keywords.addAll(kws);
    }

    return keywords.toList();
  }

  // NEW: Helper to detect similar product names (prevents duplicate mouse/keyboard/etc.)
  String _normalizeProductName(String name) {
    final lower = name.toLowerCase().trim();

    // Common brand names to strip out completely
    final brandWords = {
      'logitech',
      'hp',
      'dell',
      'lenovo',
      'asus',
      'acer',
      'apple',
      'samsung',
      'microsoft',
      'razer',
      'corsair',
      'hyperx',
      'steelseries',
      'roccat',
      'cooler',
      'master',
      'thermaltake',
      'nzxt',
      'evga',
      'gigabyte',
      'msi',
      'sony',
      'jbl',
      'bose',
      'sennheiser',
      'audio',
      'technica',
      'beats',
      'anker',
      'belkin',
      'targus',
      'kensington',
      'sandisk',
      'western',
      'digital',
      'seagate',
      'crucial',
      'kingston',
      'corsair',
      'gskill',
      'team',
      'patriot',
    };

    // Words to skip (colors, adjectives, models)
    final skipWords = {
      'black',
      'white',
      'blue',
      'red',
      'grey',
      'gray',
      'silver',
      'gold',
      'rose',
      'new',
      'original',
      'genuine',
      'authentic',
      'official',
      'plus',
      'pro',
      'max',
      'ultra',
      'super',
      'mini',
      'slim',
      'compact',
      'portable',
      'gaming',
      'rgb',
      'led',
      'mechanical',
      'optical',
      'laser',
      'wired',
      'wireless',
      'bluetooth',
      'usb',
      'type-c',
      'lightning',
      'hdmi',
      'displayport',
      'vga',
      'dvi',
    };

    // Core product types we care about (in order of priority)
    final productTypes = {
      'mouse': ['mouse', 'mice'],
      'keyboard': ['keyboard', 'keyboards'],
      'headphone': ['headphone', 'headphones', 'headset', 'headsets'],
      'earbuds': ['earbuds', 'earbud', 'earphone', 'earphones'],
      'speaker': ['speaker', 'speakers'],
      'webcam': ['webcam', 'camera'],
      'microphone': ['microphone', 'mic'],
      'hub': ['hub', 'dock', 'adapter', 'dongle'],
      'cable': ['cable', 'cord'],
      'charger': ['charger', 'adapter'],
      'powerbank': ['powerbank', 'power bank', 'battery pack'],
      'bag': ['bag', 'case', 'backpack', 'sleeve', 'pouch'],
      'stand': ['stand', 'holder', 'mount', 'arm'],
      'pad': ['pad', 'mat', 'mousepad'],
      'cleaner': ['cleaner', 'cleaning', 'wipe'],
      'cooler': ['cooler', 'cooling', 'fan'],
      'ssd': ['ssd', 'solid state'],
      'hdd': ['hdd', 'hard drive'],
      'ram': ['ram', 'memory'],
      'router': ['router'],
      'switch': ['switch'],
      'modem': ['modem'],
    };

    final words = lower.split(RegExp(r'\s+'));

    // Find the primary product type
    for (final entry in productTypes.entries) {
      final typeName = entry.key;
      final aliases = entry.value;

      for (final word in words) {
        if (aliases
            .any((alias) => word.contains(alias) || alias.contains(word))) {
          return typeName; // Return the canonical product type
        }
      }
    }

    // Fallback: extract first non-brand, non-skip word
    for (final word in words) {
      if (word.length > 2 &&
          !brandWords.contains(word) &&
          !skipWords.contains(word)) {
        return word;
      }
    }

    // Last resort: return first word
    return words.isNotEmpty ? words.first : lower;
  }

  bool _isDuplicateProduct(
      String newProductName, List<Map<String, dynamic>> existingProducts) {
    final newNorm = _normalizeProductName(newProductName);

    for (final existing in existingProducts) {
      final existingName = (existing['name'] ?? '').toString();
      final existingNorm = _normalizeProductName(existingName);

      // Check for exact normalized match
      if (newNorm == existingNorm) return true;

      // Check for substantial overlap (e.g., "wireless mouse" vs "mouse wireless")
      final newWords = newNorm.split(' ').toSet();
      final existingWords = existingNorm.split(' ').toSet();
      final intersection = newWords.intersection(existingWords);

      // If 80%+ words overlap, consider it a duplicate
      final overlapRatio = intersection.length / newWords.length;
      if (overlapRatio >= 0.8) return true;
    }

    return false;
  }

  Future<void> _fetchFrequentlyBought() async {
    if (!mounted) return;
    setState(() {
      _frequentlyBoughtLoading = true;
      _frequentlyBought = [];
      _selectedBundleItems.clear();
    });

    try {
      final productName = widget.name;
      final categoryName = widget.categoryName;
      final subcategoryName = widget.subcategoryName;

      log('==========================================');
      log('Fetching frequently bought together for: ');
      log('  Product Name: $productName');
      log('  Category: $categoryName');
      log('  Subcategory: $subcategoryName');
      log('==========================================');

      final group = _pickGroupByMatch(productName, categoryName);
      final suggestions =
          (group?['suggestions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final excludeWords =
          (group?['excludeMain'] as List?)?.cast<String>() ?? [];

      final fallbackKeywords = _extractGroupFallbackKeywords(group);

      log('Selected group has ${suggestions.length} suggestion types');
      log('Exclude words: $excludeWords');
      log('Group fallback keywords: $fallbackKeywords');

      final results = <Map<String, dynamic>>[];
      final seenIds = <String>{widget.productId};
      // NEW: track normalized names globally across all search phases
      final seenNormalizedNames = <String>{};

      // Phase 1: Try to get products from specific suggestions (if group matched)
      if (group != null) {
        for (final suggestion in suggestions) {
          if (results.length >= _maxFrequentlyBought) break;

          final keywords = (suggestion['keywords'] as List).cast<String>();
          final searches = (suggestion['searches'] as List).cast<String>();

          log('--- Trying suggestion with keywords: $keywords ---');

          // Only try first 2 searches per suggestion to save time
          for (int searchIdx = 0;
              searchIdx < searches.length && searchIdx < 2;
              searchIdx++) {
            final searchTerm = searches[searchIdx];
            if (results.length >= _maxFrequentlyBought) break;

            try {
              final url =
                  '${Configss.baseUrl}/api/products?search=${Uri.encodeComponent(searchTerm)}&limit=10';
              log('Searching: $searchTerm');

              // Add timeout
              final res = await http.get(Uri.parse(url)).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  throw TimeoutException('Search timeout: $searchTerm');
                },
              );

              if (res.statusCode == 200) {
                final body = json.decode(res.body);
                final products =
                    (body is List) ? body : (body['products'] as List? ?? []);

                log('  Found ${products.length} products for "$searchTerm"');

                for (final p in products) {
                  if (results.length >= _maxFrequentlyBought) break;
                  if (p is! Map<String, dynamic>) continue;

                  final id = (p['_id'] ?? '').toString();
                  if (seenIds.contains(id)) continue;

                  final pName = (p['name'] ?? '').toString();
                  final pNameLower = pName.toLowerCase();
                  final pCat = ((p['category'] as Map?)?['name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final combined = '$pNameLower $pCat';

                  if (_isMainProductType(combined, excludeWords)) {
                    log('  ❌ Excluding (main type): $pName');
                    continue;
                  }

                  if (!_includesAny(combined, keywords)) {
                    log('  ❌ Excluding (no keyword match): $pName');
                    continue;
                  }

                  final normalized = _normalizeProductName(pName);
                  if (seenNormalizedNames.contains(normalized)) {
                    log('  ❌ Excluding (duplicate normalized name): $pName (normalized: $normalized)');
                    continue;
                  }

                  log('  ✅ Adding: $pName (normalized: $normalized)');
                  results.add(p);
                  seenIds.add(id);
                  seenNormalizedNames.add(normalized);
                }
              }
            } on TimeoutException {
              log('⏱️ Search timeout for "$searchTerm", skipping');
            } catch (e) {
              log('Error fetching for term "$searchTerm": $e');
            }
          }
        }

        log('After specific suggestions: ${results.length} products found');
      }

      // Phase 3: UNIVERSAL FALLBACK (laptop-style for all unmapped categories)
      if (results.length < _maxFrequentlyBought) {
        log('==========================================');
        log('Using UNIVERSAL FALLBACK (laptop-style accessories)');
        log('Current results count: ${results.length}');
        log('==========================================');

        final universalExcludes = [
          'laptop',
          'notebook',
          'desktop',
          'pc',
          'workstation',
          'monitor',
          'display',
          'printer',
          'copier',
          'scanner',
          'mobile',
          'phone',
          'smartphone',
          'tablet',
          'router',
          'switch',
          'access point',
          'gaming console',
          'playstation',
          'xbox',
        ];

        // Only try first 3 searches to save time
        for (int searchIdx = 0;
            searchIdx < _genericFallbackSearches.length && searchIdx < 3;
            searchIdx++) {
          final searchTerm = _genericFallbackSearches[searchIdx];
          if (results.length >= _maxFrequentlyBought) break;

          try {
            final url =
                '${Configss.baseUrl}/api/products?search=${Uri.encodeComponent(searchTerm)}&limit=10';
            log('Universal search: $searchTerm');

            final res = await http.get(Uri.parse(url)).timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw TimeoutException('Universal search timeout: $searchTerm');
              },
            );

            if (res.statusCode == 200) {
              final body = json.decode(res.body);
              final products =
                  (body is List) ? body : (body['products'] as List? ?? []);

              log('  Found ${products.length} products for "$searchTerm"');

              for (final p in products) {
                if (results.length >= _maxFrequentlyBought) break;
                if (p is! Map<String, dynamic>) continue;

                final id = (p['_id'] ?? '').toString();
                if (seenIds.contains(id)) continue;

                final pName = (p['name'] ?? '').toString();
                final pNameLower = pName.toLowerCase();
                final pCat = ((p['category'] as Map?)?['name'] ?? '')
                    .toString()
                    .toLowerCase();
                final combined = '$pNameLower $pCat';

                if (_isMainProductType(combined, universalExcludes)) {
                  log('  Universal: ❌ Excluding (main type): $pName');
                  continue;
                }

                if (!pNameLower.contains(searchTerm.toLowerCase()) &&
                    !pCat.contains(searchTerm.toLowerCase())) {
                  continue;
                }

                final normalized = _normalizeProductName(pName);
                if (seenNormalizedNames.contains(normalized)) {
                  log('  Universal: ❌ Excluding (duplicate normalized name): $pName (normalized: $normalized)');
                  continue;
                }

                log('  Universal: ✅ Adding: $pName (normalized: $normalized)');
                results.add(p);
                seenIds.add(id);
                seenNormalizedNames.add(normalized);
              }
            }
          } on TimeoutException {
            log('⏱️ Universal search timeout for "$searchTerm", skipping');
          } catch (e) {
            log('Error in universal fallback for "$searchTerm": $e');
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _frequentlyBought = results;
        _frequentlyBoughtLoading = false;

        _selectedBundleItems[widget.productId] = true;
        final preselectCount = results.length >= _defaultPreselectedCount
            ? _defaultPreselectedCount
            : results.length;
        final preselect = results.take(preselectCount);
        for (final p in preselect) {
          final id = (p['_id'] ?? '').toString();
          if (id.isNotEmpty) _selectedBundleItems[id] = true;
        }
      });

      log('==========================================');
      log('FINAL RESULTS: ${results.length} items');
      log('Products: ${results.map((p) => p['name']).join(', ')}');
      log('Unique normalized names: ${seenNormalizedNames.toList()}');
      log('==========================================');
    } catch (e, st) {
      log('Error fetching frequently bought together: $e\n$st');
      if (mounted) {
        setState(() {
          _frequentlyBoughtLoading = false;
          _frequentlyBought = [];
        });
      }
    }
  }

  final String phoneNumber = '+971505033860';

  Future<void> _launchWhatsApp() async {
    final message = Uri.encodeComponent(
        "I'm interested in this product: ${widget.name}.\nHere is the link: ${Configss.baseUrl}");
    final Uri whatsappUrl =
        Uri.parse("https://wa.me/$phoneNumber?text=$message");
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        log("Could not launch $whatsappUrl");
      }
    } catch (e) {
      log("Could not launch WhatsApp: $e");
    }
  }

  Future<void> requestCall() async {
    final message =
        Uri.encodeComponent("I need help with this product: ${widget.name}");
    final Uri whatsappUrl =
        Uri.parse("https://wa.me/$phoneNumber?text=$message");
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        log("Could not launch $whatsappUrl for requestCall");
      }
    } catch (e) {
      log("Could not launch WhatsApp for requestCall: $e");
    }
  }

  void _shareProduct() {
    final productName = widget.name;
    final productLink = "${Configss.baseUrl}/product/${widget.productId}";
    final shareText = "Check out this product: $productName\n$productLink";
    Share.share(shareText);
  }

  String _imageFromOption(dynamic option) {
    final map = _asStringMap(option);
    final images = _imagesFromProductMap(map);
    return images.isNotEmpty ? ImageHelper.getUrl(images.first) : '';
  }

  String _priceTextFromOption(dynamic option) {
    final map = _asStringMap(option);
    final offer = _toDouble(map['offerPrice'] ?? map['salePrice']);
    final price = _toDouble(map['price'] ?? map['regularPrice']);
    final currentOffer = _toDouble(widget.offerPrice);
    final currentPrice = _toDouble(widget.price);
    final value = offer > 0
        ? offer
        : price > 0
            ? price
            : currentOffer > 0
                ? currentOffer
                : currentPrice;

    return value > 0 ? value.toStringAsFixed(2) : '';
  }

  Widget _buildProductOptions() {
    final hasColors = widget.colorVariations.isNotEmpty;
    final hasStorage = widget.variations.isNotEmpty;
    final hasModels = widget.availableModels.isNotEmpty;
    if (!hasColors && !hasStorage && !hasModels) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasColors) _buildColorVariationSection(widget.colorVariations),
        if (hasStorage)
          _buildProductReloadVariationSection(
            groupKey: 'storage',
            title: 'Available Options:',
            options: widget.variations,
            labelKeys: const [
              'variationText',
              'variantText',
              'optionText',
              'storage',
              'storageName',
              'capacity',
              'size',
              'memory',
              'name',
              'label',
              'value',
            ],
          ),
        if (hasModels)
          _buildProductReloadVariationSection(
            groupKey: 'model',
            title: hasStorage ? 'Available Models:' : 'Available Options:',
            options: widget.availableModels,
            labelKeys: const [
              'variationText',
              'variantText',
              'optionText',
              'model',
              'modelName',
              'series',
              'name',
              'label',
              'value',
            ],
          ),
      ],
    );
  }

  Widget _buildOptionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kdefblackColor,
            ),
      ),
    );
  }

  Widget _buildColorVariationSection(List options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kdefblackColor,
                  ),
              children: const [
                TextSpan(text: 'Color:'),
                TextSpan(text: 'Select Color'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(options.length, (index) {
                final option = options[index];
                final label = _optionLabel(
                  option,
                  const [
                    'color',
                    'colour',
                    'colorName',
                    'name',
                    'label',
                    'value'
                  ],
                );
                final optionProductId = _productIdFromOption(option);
                final selected = _selectedColorVariationIndex == index ||
                    (optionProductId.isNotEmpty &&
                        optionProductId == widget.productId);

                return _buildColorOptionCard(
                  option: option,
                  label: label,
                  selected: selected,
                  onTap: () => _applyColorVariation(option, index),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Select a color to view its image and price',
            style: TextStyle(
              fontSize: 13,
              color: kSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptionCard({
    required dynamic option,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final imageUrl = _imageFromOption(option);
    final priceText = _priceTextFromOption(option);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 112,
        height: 190,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF5BA2FF) : const Color(0xFFE0E3E8),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 78,
              width: 78,
              child: CachedNetworkImage(
                imageUrl: imageUrl.isNotEmpty
                    ? imageUrl
                    : _placeholderProductImageUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => Image.asset(
                  'assets/images/noimage.png',
                  fit: BoxFit.contain,
                ),
                placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kdefblackColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AED',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kdefblackColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              priceText.isNotEmpty ? priceText : '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kdefblackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductReloadVariationSection({
    required String groupKey,
    required String title,
    required List options,
    required List<String> labelKeys,
  }) {
    final stableOptions = _stableOptionsForGroup(groupKey, options, labelKeys);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOptionTitle(title),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: stableOptions.map((option) {
              final productId = option['productId'] ?? '';
              final cachedLabel = _variationProductLabels[productId];
              final label = cachedLabel != null && cachedLabel.isNotEmpty
                  ? cachedLabel
                  : (option['label'] ?? 'Option');
              final selected =
                  productId.isNotEmpty && productId == widget.productId;
              final loading = productId.isNotEmpty &&
                  productId == _reloadingVariationProductId;
              final canOpen = productId.isNotEmpty &&
                  productId != widget.productId &&
                  _reloadingVariationProductId == null;

              return _buildReloadOptionButton(
                label: label,
                selected: selected,
                loading: loading,
                enabled: canOpen,
                onTap: () => _reloadProductById(productId),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Click on any variation to view its details',
            style: TextStyle(
              fontSize: 13,
              color: kSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReloadOptionButton({
    required String label,
    required bool selected,
    required bool loading,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minWidth: 130, minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFC5DEF7) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF5BA2FF) : const Color(0xFFAAB5C4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kdefblackColor,
                ),
              ),
            ),
            if (loading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddedToCartPopup() {
    final overlayState = Overlay.of(context, rootOverlay: true);
    if (overlayState == null) {
      Get.snackbar(
        'Added to cart',
        '',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(milliseconds: 900),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

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
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (entry.mounted) entry.remove();
    });
  }

  // NEW: Bundle-specific notification showing total item count
  void _showBundleAddedToCartPopup(int itemCount) {
    log('📢 _showBundleAddedToCartPopup called with itemCount: $itemCount');

    if (!mounted) {
      log('⚠️ Widget not mounted, cannot show notification');
      return;
    }

    final overlayState = Overlay.of(context, rootOverlay: true);
    if (overlayState == null) {
      log('⚠️ Overlay not available, using GetX snackbar');
      Get.snackbar(
        'Bundle added',
        '$itemCount items added to cart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(milliseconds: 1500),
        margin: const EdgeInsets.all(16),
        isDismissible: true,
      );
      return;
    }

    log('✅ Creating overlay entry for bundle notification');

    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$itemCount items added to cart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'BUNDLE DISCOUNT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    log('✅ Overlay inserted, will remove after 1500ms');

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (entry.mounted) {
        entry.remove();
        log('✅ Overlay removed');
      }
    });
  }

  Future<void> _addBundleToCart() async {
    final cart = Get.isRegistered<CartNotifier>()
        ? Get.find<CartNotifier>()
        : Get.put(CartNotifier());
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    int totalItemsAdded = 0;
    final selectedColorData = _selectedColorCartData();

    log('🛒 Starting bundle add to cart...');

    // Add current item (suppress notification)
    final curPrice = _toDouble(
        widget.offerPrice.isNotEmpty ? widget.offerPrice : widget.price);
    final curImg = (widget.images.isNotEmpty &&
            widget.images.first is String &&
            (widget.images.first as String).isNotEmpty)
        ? widget.images.first as String
        : 'https://i.postimg.cc/SsWYSvq6/noimage.png';
    await cart.addItemInfo(
      CartOtherInfo(
        productId: widget.productId,
        productName: widget.name,
        productImage: curImg,
        productPrice: curPrice,
        originalPrice: _toDouble(widget.price) > curPrice
            ? _toDouble(widget.price)
            : curPrice,
        quantity: 1,
        selectedColorIndex:
            selectedColorData == null ? null : _selectedColorVariationIndex,
        selectedColorData: selectedColorData,
      ),
      userId,
      showNotification: false, // Suppress individual notification
    );
    totalItemsAdded++;
    log('✅ Added current item (${widget.name})');

    // Add selected extras (at discounted price, suppress notifications)
    for (final p in _frequentlyBought) {
      final id = _idOf(p);
      if (!(_selectedBundleItems[id] ?? false)) continue;
      final op = _basePrice(p);
      final dp = _discounted(op, 25);
      await cart.addItemInfo(
        CartOtherInfo(
          productId: id,
          productName: (p['name'] ?? 'Product').toString(),
          productImage: _imgOf(p),
          productPrice: dp,
          originalPrice: op,
          quantity: 1,
        ),
        userId,
        showNotification: false, // Suppress individual notification
      );
      totalItemsAdded++;
      log('✅ Added accessory: ${p['name']}');
    }

    log('🎉 Bundle complete! Showing notification for $totalItemsAdded items');

    // ✅ NEW: Manually trigger AwesomeNotifications for bundle
    final bool isNotificationEnabled =
        prefs.getBool('notification_enabled') ?? true;
    if (isNotificationEnabled) {
      log('📢 Triggering AwesomeNotification for bundle');
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: "basic_channel",
          title: "Bundle Added to Cart",
          body: '$totalItemsAdded items added with 25% bundle discount!',
          actionType: ActionType.Default,
        ),
      );
    } else {
      log('🔇 Notifications disabled, skipping AwesomeNotification');
    }

    // Show single bundle overlay notification after all items are added
    _showBundleAddedToCartPopup(totalItemsAdded);
  }

  @override
  Widget build(BuildContext context) {
    log('NewProductDetails build START ------------------------');
    log('NewProductDetails build: Product ID: ${widget.productId}, Name: ${widget.name}');
    const placeholderImage = _placeholderProductImageUrl;

    try {
      return Scaffold(
        appBar: CustomAppBar(
            titleWidget: Image.asset(
              AppImages.logoicon,
              width: 100,
              height: 100,
              color: kdefwhiteColor,
            ),
            actionicon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchScreenSecond()));
                    },
                    icon: const Icon(Icons.search,
                        color: kdefwhiteColor, size: 28)),
                GetBuilder<CartNotifier>(
                  builder: (cartNotifier) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.route(const Cart());
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
                                cartNotifier.cartOtherInfoList.length
                                    .toString(),
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
              ],
            )),
        body: SafeArea(
          child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: defaultBoxShadow,
                              color: kdefwhiteColor,
                            ),
                            key: productImageKey,
                            child: CarouselSlider.builder(
                              carouselController: _slider,
                              itemCount: widget.images.length,
                              itemBuilder: (BuildContext context, int itemIndex,
                                  int pageViewIndex) {
                                String imageUrl = _rawImageAt(itemIndex);
                                String urlForImage =
                                    ImageHelper.getUrl(imageUrl);

                                return GestureDetector(
                                  onTap: () =>
                                      _openImageViewer(initialIndex: itemIndex),
                                  child: CachedNetworkImage(
                                    imageUrl: urlForImage,
                                    imageBuilder: (context, imageProvider) =>
                                        Container(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                0.3,
                                        maxWidth:
                                            MediaQuery.of(context).size.width,
                                      ),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      height: 100,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        image: const DecorationImage(
                                          image: AssetImage(
                                            'assets/images/noimage.png',
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              options: CarouselOptions(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                autoPlay: false,
                                autoPlayInterval: const Duration(seconds: 3),
                                onPageChanged: (index, reason) {
                                  if (!mounted) return;
                                  setState(() {
                                    _currentImageIndex = index;
                                    _selectedImageUrl = _rawImageAt(index);
                                  });
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: 10,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                15.0.heightbox,
                                GestureDetector(
                                  onTap: _shareProduct,
                                  child: Image.asset(
                                    "assets/icons/share.png",
                                    width: 30,
                                    height: 30,
                                    color: kmediumblackColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      20.0.heightbox,
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: widget.images.length > 1
                              ? widget.images.map((imageItem) {
                                  int index = widget.images.indexOf(imageItem);
                                  String url = (imageItem is String
                                          ? imageItem
                                          : null) ??
                                      placeholderImage;

                                  String imageUrl = ImageHelper.getUrl(url);

                                  if (imageUrl.isEmpty)
                                    imageUrl = placeholderImage;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _currentImageIndex = index;
                                        String newSelectedImageUrl =
                                            (widget.images[index] is String
                                                    ? widget.images[index]
                                                    : null) ??
                                                placeholderImage.toString();

                                        if (newSelectedImageUrl.isEmpty)
                                          newSelectedImageUrl =
                                              placeholderImage;
                                        _selectedImageUrl = newSelectedImageUrl;
                                      });
                                      _slider.animateToPage(index);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                          right: 8.0, left: 8),
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: kdefwhiteColor,
                                        border: Border.all(
                                          color: _currentImageIndex == index
                                              ? kPrimaryColor
                                              : Colors.grey,
                                          width: _currentImageIndex == index
                                              ? 2
                                              : 1,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(
                                              imageUrl),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            log("Error loading thumbnail image: $imageUrl, error: $exception");
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList()
                              : [
                                  // Container(
                                  //   padding: EdgeInsets.all(8),
                                  //   child: const Text(
                                  //     "No additional Image available",
                                  //     style: TextStyle(
                                  //         color: kdefblackColor,
                                  //         fontWeight: FontWeight.bold),
                                  //   ),
                                  // ),
                                ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: defaultPadding(),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        10.0.heightbox,
                        AnimatedReadMoreText(
                          widget.name,
                          maxLines: 2,
                          readMoreText: 'Read More',
                          readLessText: 'Show Less',
                          textStyle:
                              Theme.of(context).textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                          buttonTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: kPrimaryColor,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Text(
                              'Category:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      fontSize: 14, color: kSecondaryColor),
                            ),
                            Expanded(
                              child: Text(
                                ' ${widget.subcategoryName.isNotEmpty ? widget.subcategoryName : widget.categoryName}',
                                // CHANGED: prefer subcategory, fallback to category
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: kPrimaryColor),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Text(
                              'Brand:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      fontSize: 14, color: kSecondaryColor),
                            ),
                            Expanded(
                              child: Text(
                                ' ${widget.brandName.isNotEmpty ? widget.brandName : "N/A"}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: widget.brandName.isNotEmpty
                                            ? kPrimaryColor
                                            : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Text(
                              'SKU:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      fontSize: 14, color: kSecondaryColor),
                            ),
                            Expanded(
                              child: Text(
                                ' ${widget.sku}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: kPrimaryColor),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        _isOutOfStock(widget.stockStatus)
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.stockCount.isNotEmpty
                                          ? ' ${widget.stockStatus} (${widget.stockCount})'
                                          : ' ${widget.stockStatus}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.red),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.stockCount.isNotEmpty
                                          ? ' Available in Stock (${widget.stockCount})'
                                          : ' Available in Stock',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: kPrimaryColor),
                                    ),
                                  ),
                                ],
                              ),
                        SizedBox(
                          height: 5,
                        ),
                        Builder(
                          builder: (context) {
                            double offerDisplayPrice =
                                double.tryParse(widget.offerPrice) ?? 0.0;
                            double regularDisplayPrice =
                                double.tryParse(widget.price) ?? 0.0;
                            const double epsilon = 0.001;

                            bool isOfferValidAndBetter =
                                offerDisplayPrice > epsilon &&
                                    offerDisplayPrice < regularDisplayPrice;

                            if (isOfferValidAndBetter) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'AED ${offerDisplayPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: kredColor),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'VAT',
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 10,
                                        color: kredColor.withOpacity(0.8)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      'AED ${regularDisplayPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ],
                              );
                            } else if (regularDisplayPrice > epsilon) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'AED ${regularDisplayPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: kdefblackColor),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'VAT',
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 10,
                                        color: kdefblackColor.withOpacity(0.8)),
                                  ),
                                ],
                              );
                            } else {
                              return const Text(
                                'Price not available',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey),
                              );
                            }
                          },
                        ),
                        10.0.heightbox,
                        _buildProductOptions(),
                        const Text(
                          "Key Features:",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kdefblackColor),
                        ),
                        // Reverted: show shortdesc as plain text (no HTML)
                        widget.shortdesc.isNotEmpty
                            ? Text(
                                removeHtmlTags(widget.shortdesc),
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kdefblackColor,
                                ),
                              )
                            : const Text(
                                'No description available.',
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                  color: kSecondaryColor,
                                ),
                              ),
                        // const SizedBox(height: 10),
                        // Builder(
                        //   builder: (_) {
                        //     final offer =
                        //         double.tryParse(widget.offerPrice) ?? 0.0;
                        //     final regular =
                        //         double.tryParse(widget.price) ?? 0.0;
                        //     const double eps = 0.0001;
                        //     final useOffer = offer > eps &&
                        //         (regular <= eps || offer < regular);
                        //     final price = useOffer ? offer : regular;
                        //     final monthly = price > eps ? (price / 4.0) : 0.0;
                        //
                        //     return GestureDetector(
                        //       onTap: () {
                        //         if (price > eps) {
                        //           Get.to(() => TamaraInfoScreen(price: price));
                        //         }
                        //       },
                        //       child: Container(
                        //         decoration: BoxDecoration(
                        //           color: Colors.white,
                        //           borderRadius: BorderRadius.circular(12),
                        //           border:
                        //               Border.all(color: Colors.grey.shade300),
                        //         ),
                        //         padding: const EdgeInsets.all(12),
                        //         child: RichText(
                        //           text: TextSpan(
                        //             style: const TextStyle(
                        //               fontSize: 12,
                        //               color: Color(0xFF374151), // gray-700
                        //             ),
                        //             children: [
                        //               const TextSpan(
                        //                   text: 'Or split in 4 payments of '),
                        //               TextSpan(
                        //                 text:
                        //                     'AED ${monthly.toStringAsFixed(2)}/mo',
                        //                 style: const TextStyle(
                        //                   fontWeight: FontWeight.w600,
                        //                   color: Color(0xFF111827), // gray-900
                        //                 ),
                        //               ),
                        //               const TextSpan(
                        //                   text:
                        //                       ' - No late fees, Sharia compliant!\n'),
                        //               const TextSpan(text: 'More options '),
                        //               WidgetSpan(
                        //                 alignment: PlaceholderAlignment.middle,
                        //                 child: Container(
                        //                   margin:
                        //                       const EdgeInsets.only(left: 6),
                        //                   padding: const EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 2),
                        //                   decoration: BoxDecoration(
                        //                     borderRadius:
                        //                         BorderRadius.circular(999),
                        //                     gradient: const LinearGradient(
                        //                       colors: [
                        //                         Color(0xFFFBCFE8),
                        //                         // pink-300
                        //                         Color(0xFFD8B4FE),
                        //                         // purple-300
                        //                         Color(0xFFBFDBFE),
                        //                         // indigo-300 (approx)
                        //                       ],
                        //                     ),
                        //                   ),
                        //                   child: const Text(
                        //                     'tamara',
                        //                     style: TextStyle(
                        //                       fontSize: 11,
                        //                       fontWeight: FontWeight.bold,
                        //                       color:
                        //                           Color(0xFF111827), // gray-900
                        //                     ),
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //     );
                        //   },
                        // ),
                        // const SizedBox(height: 8),
                        // Builder(
                        //   builder: (_) {
                        //     final offer =
                        //         double.tryParse(widget.offerPrice) ?? 0.0;
                        //     final regular =
                        //         double.tryParse(widget.price) ?? 0.0;
                        //     const double eps = 0.0001;
                        //     final useOffer = offer > eps &&
                        //         (regular <= eps || offer < regular);
                        //     final price = useOffer ? offer : regular;
                        //     final monthly12 =
                        //         price > eps ? (price / 12.0) : 0.0;
                        //     final monthly4 = price > eps
                        //         ? (price / 4.0)
                        //         : 0.0; // informational only
                        //
                        //     return GestureDetector(
                        //       onTap: () {
                        //         if (price > eps) {
                        //           Get.to(() => TabbyInfoScreen(price: price));
                        //         }
                        //       },
                        //       child: Container(
                        //         decoration: BoxDecoration(
                        //           color: Colors.white,
                        //           borderRadius: BorderRadius.circular(12),
                        //           border:
                        //               Border.all(color: Colors.grey.shade300),
                        //         ),
                        //         padding: const EdgeInsets.all(12),
                        //         child: RichText(
                        //           text: TextSpan(
                        //             style: const TextStyle(
                        //               fontSize: 12,
                        //               color: Color(0xFF374151), // gray-700
                        //             ),
                        //             children: [
                        //               const TextSpan(text: 'As low as '),
                        //               TextSpan(
                        //                 text:
                        //                     'AED ${monthly12.toStringAsFixed(2)}/mo',
                        //                 style: const TextStyle(
                        //                   fontWeight: FontWeight.w600,
                        //                   color: Color(0xFF111827), // gray-900
                        //                 ),
                        //               ),
                        //               const TextSpan(
                        //                   text:
                        //                       ' or 4 interest-free payments. '),
                        //               const TextSpan(
                        //                 text: 'Learn more',
                        //               ),
                        //               WidgetSpan(
                        //                 alignment: PlaceholderAlignment.middle,
                        //                 child: Container(
                        //                   margin:
                        //                       const EdgeInsets.only(left: 6),
                        //                   padding: const EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 3),
                        //                   decoration: BoxDecoration(
                        //                     color: Color(
                        //                         0xFF059669), // emerald-600
                        //                     borderRadius:
                        //                         BorderRadius.circular(6),
                        //                   ),
                        //                   child: const Text(
                        //                     'tabby',
                        //                     style: TextStyle(
                        //                       fontSize: 12,
                        //                       fontWeight: FontWeight.w800,
                        //                       color: Colors.white,
                        //                     ),
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //     );
                        //   },
                        // ),
                        SizedBox(
                          height: 10,
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _actionButtonWithSvg(
                                    _chat, "Chat\nWith Specialist", () {
                                  requestCall();
                                }),
                                _actionButton(
                                    Icons.phone_outlined, "Request a\nCallback",
                                    () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    builder: (context) {
                                      return RequestForm();
                                    },
                                  );
                                }),
                                _actionButton(Icons.shield_outlined,
                                    "Request Bulk\nPurchase", () {
                                  Get.to(() => BulkPurchaceView());
                                }),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.local_offer,
                                          color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        "Get My Coupon",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Free shipping when you spend AED500 & above.\n"
                                    "Unlimited destinations in Dubai and Abu Dhabi",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                    ),
                                    onPressed: () {
                                      showCouponBottomSheet(context);
                                    },
                                    child: const Text("Get My Coupon",
                                        style: TextStyle(color: Colors.black)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _infoTile(Icons.local_shipping, "Express Delivery",
                                "Free shipping when you spend AED500 & above.\nUnlimited destinations in Dubai and Abu Dhabi"),
                            const SizedBox(height: 12),
                            _infoTile(
                                Icons.refresh,
                                "Delivery & Returns Policy",
                                "Delivery in remote areas will be considered as normal delivery which takes place with 1 working day delivery."),
                            const SizedBox(height: 12),
                            _infoTile(
                                Icons.verified_user,
                                "Warranty Information",
                                "Standard warranty applies as per manufacturer terms"),
                            // NEW: Payment Methods section
                            const SizedBox(height: 19),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: Color(0xFFEEEEEE), width: 1),
                                ),
                              ),
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade600,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "Payment Methods :",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // logos column
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _pmLogo(
                                            "https://res.cloudinary.com/dyfhsu5v6/image/upload/v1757919726/1st_logo_v8x2hc.webp",
                                            "master",
                                            height: 95),
                                        const SizedBox(height: 7),
                                        _pmLogo(
                                            "https://res.cloudinary.com/dyfhsu5v6/image/upload/v1757937381/2nd_logo_x6jzhz.webp",
                                            "visa",
                                            height: 95),
                                        const SizedBox(height: 7),
                                        _pmLogo(
                                            "https://res.cloudinary.com/dyfhsu5v6/image/upload/v1757937401/3rd_logo_fmwdkp.webp",
                                            "tamara",
                                            height: 95),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Insert FBT right below Cloudinary images
                                  _buildFrequentlyBoughtSection(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                        TabBar(
                          controller: _tabController,
                          labelColor: kPrimaryColor,
                          unselectedLabelColor: Colors.black54,
                          indicatorColor: kPrimaryColor,
                          labelPadding: EdgeInsets.symmetric(horizontal: 0),
                          labelStyle: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.grey,
                          tabs: _tabs.map((e) => Tab(text: e)).toList(),
                        ),
                        Builder(
                          builder: (_) {
                            final i = _tabController.index;
                            Widget child;
                            if (i == 0) {
                              child = _buildDescription();
                            } else if (i == 1) {
                              child = buildMoreInformationTab();
                            } else {
                              child = buildReviewTab();
                            }
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: KeyedSubtree(
                                key: ValueKey<int>(i),
                                child: child,
                              ),
                            );
                          },
                        ),
                        Obx(() => _reviewCont.reviews.isNotEmpty
                            ? SizedBox(
                                height: 70,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _reviewCont.reviews.length,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final review = _reviewCont.reviews[index];
                                    return ReviewCard(review: review);
                                  },
                                ),
                              )
                            : SizedBox.shrink()),

                        20.0.heightbox,
                        Text(
                          'Related Products',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Obx(
                        () {
                          // Match Search/NewAll grid sizing: 2 columns, 0.64 aspect ratio
                          final screenW = MediaQuery.of(context).size.width;
                          const horizontalPadding = 5.0;
                          const itemGap = 8.0;
                          final cardWidth =
                              (screenW - (horizontalPadding * 2) - itemGap) / 2;
                          final cardHeight = (cardWidth / 0.64) -
                              1; // shave 1px to avoid overflow

                          if (_homeController.isrelatedLoading.value) {
                            return SizedBox(
                              height: cardHeight,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                scrollDirection: Axis.horizontal,
                                itemCount: 6,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: itemGap),
                                itemBuilder: (context, index) {
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      width: cardWidth,
                                      height: cardHeight,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }

                          final list = _homeController.relatedProducts;
                          if (list.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return SizedBox(
                            height: cardHeight,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: horizontalPadding),
                              scrollDirection: Axis.horizontal,
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: itemGap),
                              itemBuilder: (context, index) {
                                final productData = list[index];
                                return SizedBox(
                                  width: cardWidth,
                                  height: cardHeight,
                                  child: NewProductCard(
                                    prdouctList: productData,
                                    onAddedToCart: _showAddedToCartPopup,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      20.0.heightbox
                    ],
                  ),
                )
              ]),
        ),
        bottomNavigationBar: SafeArea(
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _launchWhatsApp,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      color: kSecondaryColor,
                      child: Center(
                        child: Padding(
                          padding: defaultPadding(),
                          child: Text(
                            'Order By WhatsApp',
                            style: TextStyle(
                              color: kdefwhiteColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                GetBuilder<CartNotifier>(builder: (
                  cart,
                ) {
                  bool isOutOfStock = _isOutOfStock(widget.stockStatus);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (isOutOfStock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This item is out of stock.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          final prefs = await SharedPreferences.getInstance();
                          String? userId =
                              prefs.getString('userId')?.toString();

                          // Safer image access
                          String productImageForCart = placeholderImage;
                          if (widget.images.isNotEmpty &&
                              widget.images.first is String &&
                              (widget.images.first as String).isNotEmpty) {
                            productImageForCart = widget.images.first as String;
                          } else {
                            log('Add To Cart: widget.images is empty or first item is not a valid string. Using placeholder.');
                          }

                          double offerP = double.tryParse(
                                  widget.offerPrice.isNotEmpty
                                      ? widget.offerPrice
                                      : '0') ??
                              0.0;
                          double regularP = double.tryParse(
                                  widget.price.isNotEmpty
                                      ? widget.price
                                      : '0') ??
                              0.0;
                          final selectedColorData = _selectedColorCartData();

                          cart.addItemInfo(
                              CartOtherInfo(
                                productId: widget.productId,
                                productName: widget.name,
                                productImage: productImageForCart,
                                productPrice: (offerP > 0) ? offerP : regularP,
                                originalPrice: regularP >
                                        ((offerP > 0) ? offerP : regularP)
                                    ? regularP
                                    : ((offerP > 0) ? offerP : regularP),
                                quantity: 1,
                                selectedColorIndex: selectedColorData == null
                                    ? null
                                    : _selectedColorVariationIndex,
                                selectedColorData: selectedColorData,
                              ),
                              userId);
                          _showAddedToCartPopup();
                        }
                      },
                      child: Container(
                        color: isOutOfStock ? kredColor : kPrimaryColor,
                        child: Center(
                          child: Padding(
                            padding: defaultPadding(),
                            child: Text(
                              isOutOfStock ? 'OUT OF STOCK' : 'ADD TO CART',
                              style: TextStyle(
                                color: kdefwhiteColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      log('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      log('Error in NewProductDetails build: $e');
      log('StackTrace: $stackTrace');
      log('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      return Scaffold(
        appBar: AppBar(title: Text("Error")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "An error occurred while building this page. Please try again.\n\nError: $e",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Product Description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Html(
            data: widget.description.isNotEmpty
                ? widget.description
                : '<p>No description available.</p>',
            style: {
              "body": Style(
                fontSize: FontSize(14),
                color: kdefblackColor,
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              "p": Style(margin: Margins.only(bottom: 8)),
              "strong": Style(fontWeight: FontWeight.w700),
              "b": Style(fontWeight: FontWeight.w700),
              "ul": Style(margin: Margins.only(left: 12)),
              "ol": Style(margin: Margins.only(left: 12)),
              "a": Style(
                color: kPrimaryColor,
                textDecoration: TextDecoration.underline,
              ),
              "img": Style(
                margin: Margins.only(bottom: 8),
              ),
            },
            onAnchorTap: (url, _, __) {
              if (url != null) launchUrl(Uri.parse(url));
            },
          ),
        ],
      ),
    );
  }

  String removeHtmlTags(String htmlContent) {
    if (htmlContent.isEmpty) return '';
    try {
      final document = html_parser.parse(htmlContent);
      return document.body?.text ?? '';
    } catch (e) {
      log("Error parsing HTML: $e");
      return htmlContent;
    }
  }

  bool istapped = false;
  Key descriptionKey = UniqueKey();

  Widget buildMoreInformationTab() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "More Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Brand',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                        widget.brandName.isNotEmpty ? widget.brandName : "N/A"),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Model Number',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(widget.sku),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Category',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                        widget.subcategoryName), // CHANGED: prefer subcategory
                  ),
                ],
              ),
              TableRow(
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Specifications',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  (widget.specs is List &&
                          widget.specs.isNotEmpty &&
                          widget.specs[0] is Map &&
                          widget.specs[0].containsKey('value'))
                      ? Container(
                          padding: const EdgeInsets.all(10),
                          child: Text("${widget.specs[0]['value']}"),
                        )
                      : Container(
                          padding: const EdgeInsets.all(10),
                          child: Text('No Data Available')),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildReviewTab() {
    // Use fetched reviews from controller, not widget.reviews
    final List reviewsList = _reviewCont.reviews;

    // Build rating distribution
    Map<int, int> ratingCount = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviewsList) {
      if (review is Map && review['rating'] is num) {
        final r = (review['rating'] as num).round().clamp(1, 5);
        ratingCount[r] = (ratingCount[r] ?? 0) + 1;
      }
    }

    // Prefer API stats if provided
    final int totalReviews =
        (_apiReviewStats?['totalReviews'] as num?)?.toInt() ??
            reviewsList.length;
    final double averageRating = (_apiReviewStats?['averageRating'] is num)
        ? (_apiReviewStats!['averageRating'] as num).toDouble()
        : calculateAverageRating(reviewsList);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      int star = 5 - index;
                      int count = ratingCount[star] ?? 0;
                      double percentage =
                          totalReviews == 0 ? 0 : count / totalReviews;
                      if (percentage.isNaN || percentage.isInfinite)
                        percentage = 0;

                      return Row(
                        children: [
                          Text('$star ', style: const TextStyle(fontSize: 14)),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade300,
                              color: Colors.amber,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count', style: const TextStyle(fontSize: 14)),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  decoration: const BoxDecoration(color: kPrimaryColor),
                  child: TextButton(
                    onPressed: () async {
                      final result = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) {
                          return WriteReviewScreen(productId: widget.productId);
                        },
                      );
                      if (result == true) {
                        await _onReviewAdded();
                      }
                    },
                    child: const Text('Add Review',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(5, (index) {
                        if (averageRating >= index + 1) {
                          return const Icon(Icons.star,
                              color: Colors.amber, size: 16);
                        } else if (averageRating > index &&
                            averageRating < index + 1) {
                          return const Icon(Icons.star_half,
                              color: Colors.amber, size: 16);
                        } else {
                          return const Icon(Icons.star_border,
                              color: Colors.grey, size: 16);
                        }
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text('$totalReviews Product Ratings'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_apiHasNext)
              Align(
                alignment: Alignment.center,
                child: OutlinedButton(
                  onPressed: _apiLoading
                      ? null
                      : () => _fetchReviews(page: _apiCurrentPage + 1),
                  child: _apiLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Load more reviews'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double calculateAverageRating(List reviews) {
    // ...existing code...
    double total = 0;
    int validReviewCount = 0;
    for (var review in reviews) {
      if (review is Map &&
          review.containsKey('rating') &&
          review['rating'] is num) {
        total += (review['rating'] as num);
        validReviewCount++;
      }
    }
    if (validReviewCount == 0) return 0.0;
    return total / validReviewCount;
  }

  Future<void> _onReviewAdded() async {
    // Reset local cache and re-fetch page 1
    setState(() {
      _apiCurrentPage = 1;
      _apiHasNext = false;
      _apiReviewStats = null;
      _reviewCont.reviews.clear();
    });
    await _fetchReviews(page: 1);
    // Notify other parts of the app (e.g., HomeView cards) to refresh their stats
    ReviewUpdateBus.instance.emit(widget.productId);
  }

  Widget _actionButton(IconData icon, String label, Function()? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: kPrimaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: kPrimaryColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButtonWithSvg(
      String svgString, String label, Function()? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: kPrimaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              SvgPicture.string(
                svgString,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(description, style: const TextStyle(fontSize: 13)),
            ],
          ),
        )
      ],
    );
  }

  // NEW: small helper to render payment method logo
  Widget _pmLogo(String url, String label, {double height = 48}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(),
      // keep simple, matches tailwind px-2 py-1
      child: Image.network(
        url,
        height: height, // larger logos
        fit: BoxFit.contain,
        semanticLabel: label,
        errorBuilder: (ctx, err, stack) => Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildFrequentlyBoughtSection() {
    // Show shimmer while loading
    if (_frequentlyBoughtLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(
              children: [
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 100,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Current product shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 18,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Bundle items shimmer (show 2 placeholders)
            ...List.generate(
                2,
                (index) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 12,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 10,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),

            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Totals shimmer
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 18,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state if no items found after loading
    final items = _frequentlyBought;
    if (items.isEmpty) return const SizedBox.shrink();

    final totals = _bundleTotals();

    // Original content (unchanged)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  "Frequently Bought Together",
                  softWrap: true,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(999)),
                child: const Text("25% OFF BUNDLE",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current product (always selected)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFCE8), // yellow-50
              border: Border.all(color: const Color(0xFFFDE68A)), // yellow-200
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_box, color: Color(0xFFEAB308)),
                // disabled look
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _imgOf({
                      'image': (widget.images.isNotEmpty
                          ? ImageHelper.getUrl(widget.images.first)
                          : '')
                    }),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827))),
                      const SizedBox(height: 4),
                      Text(
                        _fmt(_toDouble(widget.offerPrice.isNotEmpty
                            ? widget.offerPrice
                            : widget.price)),
                        style: const TextStyle(
                            color: Color(0xFFCA8A04),
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(999)),
                        child: const Text("Current Item",
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF92400E))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bundle items (with 25% OFF)
          Column(
            children: items.map((p) {
              final id = _idOf(p);
              final original = _basePrice(p);
              final discounted = _discounted(original, 25);
              final double savings = (original - discounted)
                  .clamp(0.0, double.infinity)
                  .toDouble();
              final alreadyDiscounted = (_toDouble(p['offerPrice']) > 0) &&
                  (_toDouble(p['offerPrice']) < _toDouble(p['price']));
              final selected = _selectedBundleItems[id] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: selected,
                      onChanged: (_) => _toggleBundleItem(id),
                      activeColor: Colors.blue,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: ImageHelper.getUrl(_imgOf(p)),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.image,
                            size: 40, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((p['name'] ?? 'Product').toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827))),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(_fmt(discounted),
                                  style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w700)),
                              Text(_fmt(original),
                                  style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(999)),
                                child: const Text("Save 25%",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFB91C1C),
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("You save ${_fmt(savings)}",
                              style: const TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          if (alreadyDiscounted) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _fmt(original),
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const Text(
                                  "Already discounted",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2563EB), // blue-600
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Totals + Add bundle
          LayoutBuilder(builder: (context, _) {
            final t = _bundleTotals();
            final canAdd = t.selectedCount > 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("Bundle price: ",
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFF374151))),
                    Text(_fmt(t.discountedTotal),
                        style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold)),
                    if (t.savings > 0)
                      Text(_fmt(t.originalTotal),
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              decoration: TextDecoration.lineThrough)),
                  ],
                ),
                if (t.savings > 0)
                  Text("You save ${_fmt(t.savings)} with bundle discount!",
                      style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                Text(
                  "For ${t.selectedCount} item${t.selectedCount != 1 ? "s" : ""}",
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAdd ? _addBundleToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "Add all ${t.selectedCount} to Cart",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (t.savings > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "Save ${_fmt(t.savings)}",
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _toggleBundleItem(String id) {
    setState(
        () => _selectedBundleItems[id] = !(_selectedBundleItems[id] ?? false));
  }

  ({
    double originalTotal,
    double discountedTotal,
    double savings,
    int selectedCount
  }) _bundleTotals() {
    // Always include current product (no extra discount)
    final currentPrice = _toDouble(
        widget.offerPrice.isNotEmpty ? widget.offerPrice : widget.price);
    double orig = currentPrice;
    double disc = currentPrice;
    int count = 1; // current item
    for (final p in _frequentlyBought) {
      final id = _idOf(p);
      if (!(_selectedBundleItems[id] ?? false)) continue;
      final op = _basePrice(p);
      final dp = _discounted(op, 25);
      orig += op;
      disc += dp;
      count += 1;
    }
    final double sav = (orig - disc).clamp(0.0, double.infinity).toDouble();
    return (
      originalTotal: orig,
      discountedTotal: disc,
      savings: sav,
      selectedCount: count
    );
  }
}

class _ProductImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ProductImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ProductImageViewer> createState() => _ProductImageViewerState();
}

class _ProductImageViewerState extends State<_ProductImageViewer> {
  late final PageController _pageController;
  List<TransformationController> _zoomControllers =
      <TransformationController>[];
  late int _currentIndex;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _zoomControllers = List.generate(
      widget.imageUrls.length,
      (_) => TransformationController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _zoomControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  bool _isZoomed(int index) {
    if (index < 0 || index >= _zoomControllers.length) return false;
    return _zoomControllers[index].value.getMaxScaleOnAxis() > 1.01;
  }

  void _toggleZoom(int index) {
    if (index < 0 || index >= _zoomControllers.length) return;

    final controller = _zoomControllers[index];
    final isZoomed = controller.value.getMaxScaleOnAxis() > 1.01;

    if (isZoomed) {
      controller.value = Matrix4.identity();
      return;
    }

    final scale = 2.5;
    final dx = -_doubleTapPosition.dx * (scale - 1);
    final dy = -_doubleTapPosition.dy * (scale - 1);
    controller.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,
                    onPageChanged: (index) {
                      if (!mounted) return;
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTapDown: (details) {
                          _doubleTapPosition = details.localPosition;
                        },
                        onDoubleTap: () => _toggleZoom(index),
                        child: Center(
                          child: InteractiveViewer(
                            key: ValueKey('viewer-$index'),
                            transformationController: _zoomControllers[index],
                            minScale: 1,
                            maxScale: 4,
                            panEnabled: _isZoomed(index),
                            scaleEnabled: true,
                            boundaryMargin: const EdgeInsets.all(80),
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrls[index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Center(
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey.shade800,
                                  highlightColor: Colors.grey.shade600,
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade700,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                padding: const EdgeInsets.all(24),
                                child: Image.asset(
                                  'assets/images/noimage.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.imageUrls.length > 1)
                  Container(
                    height: 92,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final isSelected = _currentIndex == index;
                        return GestureDetector(
                          onTap: () {
                            if (!mounted) return;
                            setState(() {
                              _currentIndex = index;
                            });
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 70,
                            height: 70,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    isSelected ? kPrimaryColor : Colors.white24,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: widget.imageUrls[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.white10,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.white10,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                  if (widget.imageUrls.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
