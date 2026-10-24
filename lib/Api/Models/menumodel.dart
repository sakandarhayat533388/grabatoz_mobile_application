import 'dart:convert';

List<Menumodel> welcomeFromJson(String str) => List<Menumodel>.from(json.decode(str).map((x) => Menumodel.fromJson(x)));

String welcomeToJson(List<Menumodel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Menumodel {
  String id;
  String name;
  String? nameAr;
  String slug;
  bool isActive;
  List<Child> children;

  Menumodel({
    required this.id,
    required this.name,
    this.nameAr,
    required this.slug,
    required this.isActive,
    required this.children,
  });

  factory Menumodel.fromJson(Map<String, dynamic> json) => Menumodel(
    id: json["_id"] ?? '',
    name: json["name"] ?? '',
    nameAr: json["nameAr"]?.toString(),
    slug: json["slug"] ?? '',
    isActive: json["isActive"] ?? false,
    children: json["children"] != null
        ? List<Child>.from(json["children"].map((x) => Child.fromJson(x))).where((child) => child.isActive).toList()
        : [],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "nameAr": nameAr,
    "slug": slug,
    "isActive": isActive,
    "children": List<dynamic>.from(children.map((x) => x.toJson())),
  };
}

class Child {
  String id;
  String name;
  String? nameAr;
  String slug;
  int level;
  String category;
  bool isActive;
  String? parentSubCategory;
  List<Child> children;

  Child({
    required this.id,
    required this.name,
    this.nameAr,
    required this.slug,
    required this.level,
    required this.category,
    required this.isActive,
    required this.parentSubCategory,
    required this.children,
  });

  factory Child.fromJson(Map<String, dynamic> json) => Child(
    id: json["_id"] ?? '',
    name: json["name"] ?? '',
    nameAr: json["nameAr"]?.toString(),
    slug: json["slug"] ?? '',
    level: json["level"] ?? 0,
    category: json["category"] ?? '',
    isActive: json["isActive"] ?? false,
    parentSubCategory: json["parentSubCategory"],
    children: json["children"] != null
        ? List<Child>.from(json["children"].map((x) => Child.fromJson(x))).where((child) => child.isActive).toList()
        : [],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "nameAr": nameAr,
    "slug": slug,
    "level": level,
    "category": category,
    "isActive": isActive,
    "parentSubCategory": parentSubCategory,
    "children": List<dynamic>.from(children.map((x) => x.toJson())),
  };
}

