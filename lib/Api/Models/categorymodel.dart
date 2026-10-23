 

class SubCategoryModel {
  String? sId;
  String? name;
  String? nameAr;
  String? slug;
  Category? category;
  bool? isActive;
  int? sortOrder;
  bool? isDeleted;
  String? createdBy;
  String? createdAt;
  String? updatedAt;
  int? iV;

  SubCategoryModel(
      {this.sId,
      this.name,
      this.nameAr,
      this.slug,
      this.category,
      this.isActive,
      this.sortOrder,
      this.isDeleted,
      this.createdBy,
      this.createdAt,
      this.updatedAt,
      this.iV});

  SubCategoryModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    nameAr = json['nameAr'];
    slug = json['slug'];
    category = json['category'] != null
        ? new Category.fromJson(json['category'])
        : null;
    isActive = json['isActive'];
    sortOrder = json['sortOrder'];
    isDeleted = json['isDeleted'];
    createdBy = json['createdBy'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['nameAr'] = this.nameAr;
    data['slug'] = this.slug;
    if (this.category != null) {
      data['category'] = this.category!.toJson();
    }
    data['isActive'] = this.isActive;
    data['sortOrder'] = this.sortOrder;
    data['isDeleted'] = this.isDeleted;
    data['createdBy'] = this.createdBy;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Category {
  String? sId;
  String? name;
  String? nameAr;
  String? slug;
  String? image;

  Category({this.sId, this.name, this.nameAr, this.slug});

  Category.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    nameAr = json['nameAr'];
    slug = json['slug'];
    image = json['image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['nameAr'] = this.nameAr;
    data['slug'] = this.slug;
    data['image'] = this.image;
    return data;
  }
}

class categoriesModel {
  String? sId;
  String? name;
  String? nameAr;
  String? slug;
  String? description;
  String? image;
  bool? isActive;
  bool? isDeleted;
  String? createdBy;
  String? createdAt;
  String? updatedAt;
  int? iV;

  categoriesModel(
      {this.sId,
      this.name,
      this.nameAr,
      this.slug,
      this.description,
      this.image,
      this.isActive,
      this.isDeleted,
      this.createdBy,
      this.createdAt,
      this.updatedAt,
      this.iV});

  categoriesModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    nameAr = json['nameAr'];
    slug = json['slug'];
    description = json['description'];
    image = json['image'];
    isActive = json['isActive'];
    isDeleted = json['isDeleted'];
    createdBy = json['createdBy'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['nameAr'] = this.nameAr;
    data['slug'] = this.slug;
    data['description'] = this.description;
    data['image'] = this.image;
    data['isActive'] = this.isActive;
    data['isDeleted'] = this.isDeleted;
    data['createdBy'] = this.createdBy;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
