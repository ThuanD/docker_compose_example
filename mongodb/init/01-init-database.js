// MongoDB Database Initialization Script
// This script runs automatically when the database is created for the first time

// Switch to the application database
db = db.getSiblingDB('mydatabase');

// Create a user for the application database
db.createUser({
  user: 'appuser',
  pwd: 'apppassword',
  roles: [
    {
      role: 'readWrite',
      db: 'mydatabase'
    }
  ]
});

// Create sample collections with documents
db.users.insertMany([
  {
    username: 'john_doe',
    email: 'john@example.com',
    firstName: 'John',
    lastName: 'Doe',
    age: 30,
    isActive: true,
    createdAt: new Date(),
    profile: {
      bio: 'Software developer with 5 years of experience',
      skills: ['JavaScript', 'Python', 'MongoDB', 'Docker'],
      social: {
        twitter: '@johndoe',
        linkedin: 'linkedin.com/in/johndoe'
      }
    },
    preferences: {
      theme: 'dark',
      notifications: {
        email: true,
        push: false
      }
    }
  },
  {
    username: 'jane_smith',
    email: 'jane@example.com',
    firstName: 'Jane',
    lastName: 'Smith',
    age: 28,
    isActive: true,
    createdAt: new Date(),
    profile: {
      bio: 'Data scientist and machine learning enthusiast',
      skills: ['Python', 'R', 'TensorFlow', 'MongoDB', 'SQL'],
      social: {
        twitter: '@janesmith',
        github: 'github.com/janesmith'
      }
    },
    preferences: {
      theme: 'light',
      notifications: {
        email: true,
        push: true
      }
    }
  },
  {
    username: 'admin_user',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    age: 35,
    isActive: true,
    createdAt: new Date(),
    role: 'administrator',
    profile: {
      bio: 'System administrator',
      skills: ['DevOps', 'Docker', 'Kubernetes', 'MongoDB'],
      social: {}
    },
    preferences: {
      theme: 'dark',
      notifications: {
        email: true,
        push: true
      }
    }
  }
]);

db.products.insertMany([
  {
    name: 'Laptop Computer',
    description: 'High-performance laptop for development',
    price: 999.99,
    category: 'Electronics',
    stock: 50,
    specifications: {
      cpu: 'Intel i7',
      ram: '16GB',
      storage: '512GB SSD',
      screen: '15.6 inch',
      weight: '2.1kg'
    },
    tags: ['laptop', 'computer', 'development', 'portable'],
    isActive: true,
    createdAt: new Date(),
    reviews: [
      {
        userId: 'john_doe',
        rating: 5,
        comment: 'Excellent laptop for development work',
        createdAt: new Date()
      },
      {
        userId: 'jane_smith',
        rating: 4,
        comment: 'Great performance, slightly heavy',
        createdAt: new Date()
      }
    ]
  },
  {
    name: 'MongoDB Guide Book',
    description: 'Complete guide to MongoDB development',
    price: 29.99,
    category: 'Books',
    stock: 100,
    specifications: {
      pages: 450,
      language: 'English',
      format: 'Paperback',
      isbn: '978-1234567890'
    },
    tags: ['book', 'mongodb', 'database', 'nosql', 'development'],
    isActive: true,
    createdAt: new Date(),
    reviews: [
      {
        userId: 'admin_user',
        rating: 5,
        comment: 'Comprehensive guide for MongoDB',
        createdAt: new Date()
      }
    ]
  },
  {
    name: 'Docker T-Shirt',
    description: 'Comfortable cotton t-shirt with Docker logo',
    price: 19.99,
    category: 'Clothing',
    stock: 200,
    specifications: {
      material: '100% Cotton',
      sizes: ['S', 'M', 'L', 'XL'],
      color: 'Blue',
      care: 'Machine washable'
    },
    tags: ['clothing', 'docker', 'developer', 'cotton'],
    isActive: true,
    createdAt: new Date(),
    reviews: []
  }
]);

db.categories.insertMany([
  {
    name: 'Electronics',
    description: 'Electronic devices and gadgets',
    parentCategory: null,
    isActive: true,
    createdAt: new Date()
  },
  {
    name: 'Books',
    description: 'Books and publications',
    parentCategory: null,
    isActive: true,
    createdAt: new Date()
  },
  {
    name: 'Clothing',
    description: 'Clothing and accessories',
    parentCategory: null,
    isActive: true,
    createdAt: new Date()
  },
  {
    name: 'Technical Books',
    description: 'Programming and technical books',
    parentCategory: 'Books',
    isActive: true,
    createdAt: new Date()
  }
]);

db.orders.insertMany([
  {
    userId: 'john_doe',
    orderNumber: 'ORD-001',
    items: [
      {
        productId: ObjectId(),
        productName: 'Laptop Computer',
        quantity: 1,
        unitPrice: 999.99,
        totalPrice: 999.99
      }
    ],
    totalAmount: 999.99,
    status: 'completed',
    shippingAddress: {
      street: '123 Main St',
      city: 'New York',
      state: 'NY',
      zipCode: '10001',
      country: 'USA'
    },
    paymentMethod: 'credit_card',
    orderDate: new Date(),
    shippedDate: new Date(),
    deliveredDate: new Date()
  },
  {
    userId: 'jane_smith',
    orderNumber: 'ORD-002',
    items: [
      {
        productId: ObjectId(),
        productName: 'MongoDB Guide Book',
        quantity: 2,
        unitPrice: 29.99,
        totalPrice: 59.98
      },
      {
        productId: ObjectId(),
        productName: 'Docker T-Shirt',
        quantity: 1,
        unitPrice: 19.99,
        totalPrice: 19.99
      }
    ],
    totalAmount: 79.97,
    status: 'shipped',
    shippingAddress: {
      street: '456 Oak Ave',
      city: 'San Francisco',
      state: 'CA',
      zipCode: '94102',
      country: 'USA'
    },
    paymentMethod: 'paypal',
    orderDate: new Date(),
    shippedDate: new Date()
  }
]);

// Create indexes for better performance
db.users.createIndex({ username: 1 }, { unique: true });
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ 'profile.skills': 1 });
db.users.createIndex({ isActive: 1 });

db.products.createIndex({ name: 1 });
db.products.createIndex({ category: 1 });
db.products.createIndex({ tags: 1 });
db.products.createIndex({ price: 1 });
db.products.createIndex({ isActive: 1 });

db.orders.createIndex({ userId: 1 });
db.orders.createIndex({ orderNumber: 1 }, { unique: true });
db.orders.createIndex({ status: 1 });
db.orders.createIndex({ orderDate: 1 });

db.categories.createIndex({ name: 1 }, { unique: true });
db.categories.createIndex({ parentCategory: 1 });

// Create a view for order summaries
db.createView('orderSummaries', 'orders', [
  {
    $lookup: {
      from: 'users',
      localField: 'userId',
      foreignField: 'username',
      as: 'userInfo'
    }
  },
  {
    $project: {
      orderNumber: 1,
      totalAmount: 1,
      status: 1,
      orderDate: 1,
      itemCount: { $size: '$items' },
      customerName: { 
        $concat: [
          { $arrayElemAt: ['$userInfo.firstName', 0] },
          ' ',
          { $arrayElemAt: ['$userInfo.lastName', 0] }
        ]
      },
      customerEmail: { $arrayElemAt: ['$userInfo.email', 0] }
    }
  }
]);

print('MongoDB database initialization completed successfully!');
print('Created collections: users, products, categories, orders');
print('Created indexes for performance optimization');
print('Created view: orderSummaries');
print('Inserted sample data for testing');
print('Created application user: appuser');
print('Database is ready for use!');