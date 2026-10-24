import 'package:get/get.dart';
import 'package:graba2z/Controllers/language_controller.dart';
import 'package:graba2z/Views/Home/Screens/Shop%20Screen/Shop.dart';
import '../Api/Models/menumodel.dart';
import '../Utils/packages.dart';
import '../Views/Product Folder/new_all_products.dart';

class CategoryTile extends StatefulWidget {
  final String title;
  final String? titleAr;
  final String slug;
  final List<Child> children;
  final String id;
  final int level;

  const CategoryTile({
    Key? key,
    required this.title,
    this.titleAr,
    required this.slug,
    required this.children,
    required this.id,
    this.level = 0,
  }) : super(key: key);

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _isExpanded = false;

  String get _displayTitle {
    final bool isAr = Get.isRegistered<LanguageController>() &&
        Get.find<LanguageController>().isArabic;
    if (isAr && (widget.titleAr?.trim().isNotEmpty ?? false)) {
      return widget.titleAr!;
    }
    return widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.level.isEven ? Colors.black : Colors.red;
    final parentType =
    widget.level == 0 ? 'parentCategory' : 'subcategory';

    // ---------------- Calculate padding ----------------
    double leftPadding = 16 + widget.level * 16;
    if (leftPadding > 48) leftPadding = 48; // cap at 48 for deep levels

    // ---------------- LEAF ----------------
    if (widget.children.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.only(left: leftPadding, right: 20),
        title: Text(
          _displayTitle,
          style: TextStyle(color: textColor),
        ),
        onTap: () {
          debugPrint(
              "TAP → level=${widget.level}, id=${widget.id}, type=$parentType");

          Get.to(() => Shop(
            id: widget.id,
            parentType: parentType,
            displayTitle: _displayTitle,
          ));
        },
      );
    }

    // ---------------- NODE ----------------
    return Column(
      children: [
        InkWell(
          onTap: () {
            debugPrint(
                "TAP → level=${widget.level}, id=${widget.id}, type=$parentType");

            Get.to(() => Shop(
              id: widget.id,
              parentType: parentType,
              displayTitle: _displayTitle,
            ));
          },
          child: Container(
            height: 50,
            padding: EdgeInsets.only(left: leftPadding, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ---------------- Text with proper overflow ----------------
                Expanded(
                  child: Text(
                    _displayTitle,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis, // prevents overflow
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ---------------- CHILDREN ----------------
        if (_isExpanded)
          Column(
            children: widget.children.map((child) {
              return CategoryTile(
                title: child.name,
                titleAr: child.nameAr,
                slug: child.slug,
                id: child.id,
                children: child.children,
                level: widget.level + 1,
              );
            }).toList(),
          ),
      ],
    );
  }
}
