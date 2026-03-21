/// Models for /api/v1/public/courses, /courses/{id}, /batches/{id}

class PublicCourseType {
  final String id;
  final String name;
  final String type; // karir | reguler | privat | sertifikasi

  const PublicCourseType({
    required this.id,
    required this.name,
    required this.type,
  });

  factory PublicCourseType.fromJson(Map<String, dynamic> json) =>
      PublicCourseType(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
      );
}

class PublicCourse {
  final String id;
  final String name;
  final String description;
  final String field;
  final String thumbnailUrl;
  final PublicCourseType? courseType;
  final String departmentName;
  final int priceFrom;
  final int batchCount;
  final int studentCount;
  final String? nextBatchDate;

  const PublicCourse({
    required this.id,
    required this.name,
    required this.description,
    required this.field,
    required this.thumbnailUrl,
    this.courseType,
    required this.departmentName,
    required this.priceFrom,
    required this.batchCount,
    this.studentCount = 0,
    this.nextBatchDate,
  });

  factory PublicCourse.fromJson(Map<String, dynamic> json) {
    final ctJson = json['course_type'];
    final deptJson = json['department'];
    return PublicCourse(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      field: json['field'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      courseType: ctJson != null
          ? PublicCourseType.fromJson(ctJson as Map<String, dynamic>)
          : null,
      departmentName: deptJson != null
          ? (deptJson as Map<String, dynamic>)['name'] as String? ?? ''
          : '',
      priceFrom: (json['price_from'] as num?)?.toInt() ?? 0,
      batchCount: (json['batch_count'] as num?)?.toInt() ?? 0,
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      nextBatchDate: json['next_batch_date'] as String?,
    );
  }
}

class PublicCourseListResult {
  final List<PublicCourse> data;
  final int total;

  const PublicCourseListResult({required this.data, required this.total});

  factory PublicCourseListResult.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = raw is List ? raw : [];
    return PublicCourseListResult(
      data: list
          .map((e) => PublicCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  static PublicCourseListResult mock() {
    final types = [
      const PublicCourseType(id: 't1', name: 'Program Karir', type: 'karir'),
      const PublicCourseType(id: 't2', name: 'Reguler', type: 'reguler'),
      const PublicCourseType(id: 't3', name: 'Privat', type: 'privat'),
      const PublicCourseType(id: 't4', name: 'Sertifikasi', type: 'sertifikasi'),
    ];
    final courses = [
      PublicCourse(
        id: 'mock-1',
        name: 'Web Development Fullstack',
        description: 'Kuasai pengembangan web dari frontend hingga backend dengan teknologi terkini.',
        field: 'teknologi',
        thumbnailUrl: '',
        courseType: types[0],
        departmentName: 'Web & Mobile Development',
        priceFrom: 8000000,
        batchCount: 3,
        studentCount: 124,
      ),
      PublicCourse(
        id: 'mock-2',
        name: 'UI/UX Design Profesional',
        description: 'Rancang pengalaman pengguna yang memukau dengan Figma dan prinsip desain modern.',
        field: 'desain',
        thumbnailUrl: '',
        courseType: types[1],
        departmentName: 'UI/UX Design',
        priceFrom: 3500000,
        batchCount: 2,
        studentCount: 87,
      ),
      PublicCourse(
        id: 'mock-3',
        name: 'Data Science & Machine Learning',
        description: 'Analisis data dan bangun model prediktif dengan Python, pandas, dan scikit-learn.',
        field: 'data',
        thumbnailUrl: '',
        courseType: types[0],
        departmentName: 'Data Science & AI',
        priceFrom: 9000000,
        batchCount: 2,
        studentCount: 65,
      ),
      PublicCourse(
        id: 'mock-4',
        name: 'Digital Marketing Masterclass',
        description: 'Strategi pemasaran digital komprehensif: SEO, SEM, Social Media, dan Content Marketing.',
        field: 'marketing',
        thumbnailUrl: '',
        courseType: types[1],
        departmentName: 'Digital Marketing',
        priceFrom: 2500000,
        batchCount: 4,
        studentCount: 210,
      ),
      PublicCourse(
        id: 'mock-5',
        name: 'Mobile App Development Flutter',
        description: 'Bangun aplikasi mobile cross-platform berkualitas tinggi dengan Flutter dan Dart.',
        field: 'teknologi',
        thumbnailUrl: '',
        courseType: types[0],
        departmentName: 'Web & Mobile Development',
        priceFrom: 8500000,
        batchCount: 2,
        studentCount: 93,
      ),
      PublicCourse(
        id: 'mock-6',
        name: 'Kursus Privat Python Dasar',
        description: 'Belajar Python dari nol secara privat dengan jadwal fleksibel sesuai kebutuhanmu.',
        field: 'teknologi',
        thumbnailUrl: '',
        courseType: types[2],
        departmentName: 'Data Science & AI',
        priceFrom: 500000,
        batchCount: 1,
        studentCount: 12,
      ),
      PublicCourse(
        id: 'mock-7',
        name: 'Sertifikasi Cloud Computing AWS',
        description: 'Persiapan ujian sertifikasi AWS Cloud Practitioner dan Solutions Architect.',
        field: 'teknologi',
        thumbnailUrl: '',
        courseType: types[3],
        departmentName: 'Web & Mobile Development',
        priceFrom: 1500000,
        batchCount: 3,
        studentCount: 156,
      ),
      PublicCourse(
        id: 'mock-8',
        name: 'Business Analytics & Excel Pro',
        description: 'Analisis bisnis menggunakan Excel lanjutan, Power BI, dan dashboard interaktif.',
        field: 'bisnis',
        thumbnailUrl: '',
        courseType: types[1],
        departmentName: 'Digital Marketing',
        priceFrom: 2000000,
        batchCount: 2,
        studentCount: 74,
      ),
    ];
    return PublicCourseListResult(data: courses, total: courses.length);
  }
}

class PublicSchedule {
  final String id;
  final String scheduledAt;
  final int durationMinutes;
  final String moduleTitle;
  final String roomName;

  const PublicSchedule({
    required this.id,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.moduleTitle,
    required this.roomName,
  });

  factory PublicSchedule.fromJson(Map<String, dynamic> json) => PublicSchedule(
        id: json['id'] as String? ?? '',
        scheduledAt: json['scheduled_at'] as String? ?? '',
        durationMinutes:
            (json['duration_minutes'] as num?)?.toInt() ?? 0,
        moduleTitle: json['module_title'] as String? ?? '',
        roomName: json['room_name'] as String? ?? '',
      );
}

class PublicBatch {
  final String id;
  final String courseId;
  final String courseName;
  final String courseType;
  final String facilitatorName;
  final int price;
  final String paymentMethod;
  final int maxStudents;
  final int enrolledCount;
  final String startDate;
  final String? endDate;
  final String status;
  final String location;
  final List<PublicSchedule> schedules;

  const PublicBatch({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.courseType,
    required this.facilitatorName,
    required this.price,
    required this.paymentMethod,
    required this.maxStudents,
    required this.enrolledCount,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.location,
    required this.schedules,
  });

  int get availableSlots => maxStudents - enrolledCount;
  bool get isFull => availableSlots <= 0;

  factory PublicBatch.fromJson(Map<String, dynamic> json) {
    final schedRaw = json['schedules'] as List? ?? [];
    return PublicBatch(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      courseName: json['course_name'] as String? ?? '',
      courseType: json['course_type'] as String? ?? '',
      facilitatorName: json['facilitator_name'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? '',
      maxStudents: (json['max_students'] as num?)?.toInt() ?? 0,
      enrolledCount: (json['enrolled_count'] as num?)?.toInt() ?? 0,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String?,
      status: json['status'] as String? ?? '',
      location: json['location'] as String? ?? '',
      schedules: schedRaw
          .map((e) => PublicSchedule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static PublicBatch mock() => const PublicBatch(
        id: 'mock-batch',
        courseId: 'mock-course',
        courseName: 'Web Development Fullstack',
        courseType: 'Program Karir',
        facilitatorName: 'Andi Pratama',
        price: 8000000,
        paymentMethod: 'scheduled',
        maxStudents: 20,
        enrolledCount: 15,
        startDate: '2026-04-07',
        endDate: '2026-07-14',
        status: 'active',
        location: 'Gedung A, Ruang 101',
        schedules: [
          PublicSchedule(
            id: 's1',
            scheduledAt: '2026-04-07T09:00:00',
            durationMinutes: 120,
            moduleTitle: 'Pengenalan HTML & CSS',
            roomName: 'Ruang 101',
          ),
          PublicSchedule(
            id: 's2',
            scheduledAt: '2026-04-14T09:00:00',
            durationMinutes: 120,
            moduleTitle: 'JavaScript Dasar',
            roomName: 'Ruang 101',
          ),
          PublicSchedule(
            id: 's3',
            scheduledAt: '2026-04-21T09:00:00',
            durationMinutes: 120,
            moduleTitle: 'React.js Fundamentals',
            roomName: 'Ruang 101',
          ),
        ],
      );
}

class PublicCourseDetail {
  final String id;
  final String name;
  final String description;
  final String field;
  final String thumbnailUrl;
  final PublicCourseType? courseType;
  final String departmentName;
  final List<PublicBatch> availableBatches;
  final List<String> objectives;
  final List<String> requirements;

  const PublicCourseDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.field,
    required this.thumbnailUrl,
    this.courseType,
    required this.departmentName,
    required this.availableBatches,
    required this.objectives,
    required this.requirements,
  });

  factory PublicCourseDetail.fromJson(Map<String, dynamic> json) {
    final ctJson = json['course_type'];
    final deptJson = json['department'];
    final batchesRaw = json['available_batches'] as List? ?? [];
    final objRaw = json['objectives'] as List? ?? [];
    final reqRaw = json['requirements'] as List? ?? [];
    return PublicCourseDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      field: json['field'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      courseType: ctJson != null
          ? PublicCourseType.fromJson(ctJson as Map<String, dynamic>)
          : null,
      departmentName: deptJson != null
          ? (deptJson as Map<String, dynamic>)['name'] as String? ?? ''
          : '',
      availableBatches: batchesRaw
          .map((e) => PublicBatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      objectives: objRaw.map((e) => e.toString()).toList(),
      requirements: reqRaw.map((e) => e.toString()).toList(),
    );
  }
}

// ─── Extended models for V2 course detail ─────────────────────────────────────

/// Extended course type with pricing/duration/participants
class PublicCourseTypeDetail {
  final String id;
  final String name;
  final String type; // karir | reguler | privat | sertifikasi | kolaborasi | inhouse
  final int normalPrice;
  final int minPrice;
  final int minParticipants;
  final int maxParticipants;
  final int sessionCount;
  final bool hasCertParticipant;
  final bool hasCertCompetency;
  final List<PublicBatch> batches;

  const PublicCourseTypeDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.normalPrice,
    required this.minPrice,
    required this.minParticipants,
    required this.maxParticipants,
    required this.sessionCount,
    required this.hasCertParticipant,
    required this.hasCertCompetency,
    required this.batches,
  });

  factory PublicCourseTypeDetail.fromJson(Map<String, dynamic> json) {
    final batchesRaw = json['batches'] as List? ?? [];
    return PublicCourseTypeDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      normalPrice: (json['normal_price'] as num?)?.toInt() ?? 0,
      minPrice: (json['min_price'] as num?)?.toInt() ?? 0,
      minParticipants: (json['min_participants'] as num?)?.toInt() ?? 1,
      maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 20,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      hasCertParticipant: json['has_cert_participant'] as bool? ?? false,
      hasCertCompetency: json['has_cert_competency'] as bool? ?? false,
      batches: batchesRaw
          .map((e) => PublicBatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Facilitator info for course detail
class PublicFacilitator {
  final String id;
  final String name;
  final String level;
  final String bio;
  final String? photoUrl;

  const PublicFacilitator({
    required this.id,
    required this.name,
    required this.level,
    required this.bio,
    this.photoUrl,
  });

  factory PublicFacilitator.fromJson(Map<String, dynamic> json) =>
      PublicFacilitator(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        level: json['level'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
      );
}

/// Testimonial for course detail
class PublicTestimonial {
  final String id;
  final String name;
  final String? photoUrl;
  final String message;
  final String courseTypeName;
  final double rating;
  final String date;

  const PublicTestimonial({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.message,
    required this.courseTypeName,
    required this.rating,
    required this.date,
  });

  factory PublicTestimonial.fromJson(Map<String, dynamic> json) =>
      PublicTestimonial(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        message: json['message'] as String? ?? '',
        courseTypeName: json['course_type_name'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        date: json['date'] as String? ?? '',
      );
}

/// FAQ item for course detail
class PublicFaq {
  final String id;
  final String question;
  final String answer;

  const PublicFaq({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory PublicFaq.fromJson(Map<String, dynamic> json) => PublicFaq(
        id: json['id'] as String? ?? '',
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
      );
}

/// Department for filter
class PublicDepartment {
  final String id;
  final String name;

  const PublicDepartment({required this.id, required this.name});

  factory PublicDepartment.fromJson(Map<String, dynamic> json) =>
      PublicDepartment(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

/// Extended course detail V2 with all sections
class PublicCourseDetailV2 {
  final String id;
  final String name;
  final String description;
  final String shortDesc;
  final String field;
  final String thumbnailUrl;
  final String departmentName;
  final int totalStudents;
  final int totalBatches;
  final double rating;
  final List<String> objectives;
  final List<String> requirements;
  final List<PublicCourseTypeDetail> courseTypes;
  final List<PublicFacilitator> facilitators;
  final List<PublicTestimonial> testimonials;
  final List<PublicFaq> faqs;

  const PublicCourseDetailV2({
    required this.id,
    required this.name,
    required this.description,
    required this.shortDesc,
    required this.field,
    required this.thumbnailUrl,
    required this.departmentName,
    required this.totalStudents,
    required this.totalBatches,
    required this.rating,
    required this.objectives,
    required this.requirements,
    required this.courseTypes,
    required this.facilitators,
    required this.testimonials,
    required this.faqs,
  });

  factory PublicCourseDetailV2.fromJson(Map<String, dynamic> json) {
    final deptJson = json['department'];
    final typesRaw = json['course_types'] as List? ?? [];
    final facilRaw = json['facilitators'] as List? ?? [];
    final testiRaw = json['testimonials'] as List? ?? [];
    final faqRaw = json['faqs'] as List? ?? [];
    final objRaw = json['objectives'] as List? ?? [];
    final reqRaw = json['requirements'] as List? ?? [];

    return PublicCourseDetailV2(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      shortDesc: json['short_desc'] as String? ?? json['description'] as String? ?? '',
      field: json['field'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      departmentName: deptJson != null
          ? (deptJson as Map<String, dynamic>)['name'] as String? ?? ''
          : json['department_name'] as String? ?? '',
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      totalBatches: (json['total_batches'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      objectives: objRaw.map((e) => e.toString()).toList(),
      requirements: reqRaw.map((e) => e.toString()).toList(),
      courseTypes: typesRaw
          .map((e) => PublicCourseTypeDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      facilitators: facilRaw
          .map((e) => PublicFacilitator.fromJson(e as Map<String, dynamic>))
          .toList(),
      testimonials: testiRaw
          .map((e) => PublicTestimonial.fromJson(e as Map<String, dynamic>))
          .toList(),
      faqs: faqRaw
          .map((e) => PublicFaq.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static PublicCourseDetailV2 mock() => const PublicCourseDetailV2(
        id: 'mock-course',
        name: 'Web Development Fullstack',
        description:
            'Program intensif pengembangan web fullstack yang mencakup frontend modern dengan React.js, backend dengan Node.js/Go, database PostgreSQL, hingga deployment ke cloud. Kamu akan mengerjakan proyek nyata dan membangun portfolio profesional yang siap digunakan untuk melamar kerja atau merintis startup.',
        shortDesc:
            'Kuasai pengembangan web dari frontend hingga backend. Bangun portfolio nyata dan siap kerja dalam 6 bulan.',
        field: 'teknologi',
        thumbnailUrl: '',
        departmentName: 'Web & Mobile Development',
        totalStudents: 312,
        totalBatches: 8,
        rating: 4.8,
        objectives: [
          'Membangun aplikasi web fullstack dari nol',
          'Menguasai React.js dan modern frontend tooling',
          'Memahami REST API dan arsitektur backend',
          'Bekerja dengan database relasional (PostgreSQL)',
          'Deployment aplikasi ke cloud (AWS/GCP)',
          'Workflow profesional: Git, CI/CD, code review',
        ],
        requirements: [
          'Tidak memerlukan pengalaman programming sebelumnya',
          'Memiliki laptop dengan RAM minimal 8GB',
          'Bersedia belajar minimal 20 jam per minggu',
          'Motivasi tinggi dan konsisten',
        ],
        courseTypes: [
          PublicCourseTypeDetail(
            id: 'ct-karir',
            name: 'Program Karir',
            type: 'karir',
            normalPrice: 10000000,
            minPrice: 8000000,
            minParticipants: 5,
            maxParticipants: 15,
            sessionCount: 24,
            hasCertParticipant: true,
            hasCertCompetency: true,
            batches: [
              PublicBatch(
                id: 'batch-april',
                courseId: 'mock-course',
                courseName: 'Web Development Fullstack',
                courseType: 'Program Karir',
                facilitatorName: 'Andi Pratama',
                price: 9000000,
                paymentMethod: 'scheduled',
                maxStudents: 15,
                enrolledCount: 11,
                startDate: '2026-04-07',
                endDate: '2026-07-14',
                status: 'active',
                location: 'Gedung A, Ruang 101',
                schedules: [
                  PublicSchedule(
                    id: 'sa1',
                    scheduledAt: '2026-04-07T09:00:00',
                    durationMinutes: 120,
                    moduleTitle: 'Pengenalan HTML & CSS',
                    roomName: 'Ruang 101',
                  ),
                  PublicSchedule(
                    id: 'sa2',
                    scheduledAt: '2026-04-14T09:00:00',
                    durationMinutes: 120,
                    moduleTitle: 'JavaScript Dasar',
                    roomName: 'Ruang 101',
                  ),
                  PublicSchedule(
                    id: 'sa3',
                    scheduledAt: '2026-04-21T09:00:00',
                    durationMinutes: 120,
                    moduleTitle: 'React.js Fundamentals',
                    roomName: 'Ruang 101',
                  ),
                ],
              ),
              PublicBatch(
                id: 'batch-mei',
                courseId: 'mock-course',
                courseName: 'Web Development Fullstack',
                courseType: 'Program Karir',
                facilitatorName: 'Siti Rahayu',
                price: 8500000,
                paymentMethod: 'upfront',
                maxStudents: 15,
                enrolledCount: 5,
                startDate: '2026-05-05',
                endDate: '2026-08-10',
                status: 'active',
                location: 'Gedung B, Ruang 203',
                schedules: [
                  PublicSchedule(
                    id: 'sb1',
                    scheduledAt: '2026-05-05T13:00:00',
                    durationMinutes: 120,
                    moduleTitle: 'Pengenalan HTML & CSS',
                    roomName: 'Ruang 203',
                  ),
                  PublicSchedule(
                    id: 'sb2',
                    scheduledAt: '2026-05-12T13:00:00',
                    durationMinutes: 120,
                    moduleTitle: 'JavaScript Dasar',
                    roomName: 'Ruang 203',
                  ),
                  PublicSchedule(
                    id: 'sb3',
                    scheduledAt: '2026-05-19T13:00:00',
                    durationMinutes: 120,
                    moduleTitle: 'React.js Fundamentals',
                    roomName: 'Ruang 203',
                  ),
                ],
              ),
            ],
          ),
          PublicCourseTypeDetail(
            id: 'ct-reguler',
            name: 'Reguler',
            type: 'reguler',
            normalPrice: 4500000,
            minPrice: 3500000,
            minParticipants: 3,
            maxParticipants: 20,
            sessionCount: 12,
            hasCertParticipant: true,
            hasCertCompetency: false,
            batches: [
              PublicBatch(
                id: 'batch-reg-april',
                courseId: 'mock-course',
                courseName: 'Web Development Fullstack',
                courseType: 'Reguler',
                facilitatorName: 'Andi Pratama',
                price: 4000000,
                paymentMethod: 'upfront',
                maxStudents: 20,
                enrolledCount: 8,
                startDate: '2026-04-10',
                endDate: '2026-06-27',
                status: 'active',
                location: 'Gedung A, Ruang 102',
                schedules: [
                  PublicSchedule(
                    id: 'sr1',
                    scheduledAt: '2026-04-10T18:00:00',
                    durationMinutes: 90,
                    moduleTitle: 'HTML & CSS Essentials',
                    roomName: 'Ruang 102',
                  ),
                  PublicSchedule(
                    id: 'sr2',
                    scheduledAt: '2026-04-17T18:00:00',
                    durationMinutes: 90,
                    moduleTitle: 'JavaScript Modern',
                    roomName: 'Ruang 102',
                  ),
                  PublicSchedule(
                    id: 'sr3',
                    scheduledAt: '2026-04-24T18:00:00',
                    durationMinutes: 90,
                    moduleTitle: 'Intro to React',
                    roomName: 'Ruang 102',
                  ),
                ],
              ),
            ],
          ),
        ],
        facilitators: [
          PublicFacilitator(
            id: 'f1',
            name: 'Andi Pratama',
            level: 'Senior Instructor',
            bio:
                '8 tahun pengalaman sebagai Full Stack Developer di startup dan korporat. Pernah bekerja di Tokopedia dan memiliki passion dalam mentoring developer muda.',
          ),
          PublicFacilitator(
            id: 'f2',
            name: 'Siti Rahayu',
            level: 'Lead Instructor',
            bio:
                'Software Engineer berpengalaman 6 tahun, spesialis React dan Node.js. Kontributor open source dan pembicara di beberapa tech conference nasional.',
          ),
        ],
        testimonials: [
          PublicTestimonial(
            id: 'tm1',
            name: 'Budi Santoso',
            message:
                'Program Karir ini benar-benar mengubah hidupku. Dari tidak tahu coding sama sekali, sekarang aku sudah bekerja sebagai Junior Developer di perusahaan teknologi.',
            courseTypeName: 'Program Karir',
            rating: 5.0,
            date: '2026-01-15',
          ),
          PublicTestimonial(
            id: 'tm2',
            name: 'Rina Wulandari',
            message:
                'Materi sangat komprehensif dan up-to-date. Fasilitatornya sangat sabar dan selalu siap membantu. Highly recommended!',
            courseTypeName: 'Reguler',
            rating: 4.5,
            date: '2026-02-03',
          ),
          PublicTestimonial(
            id: 'tm3',
            name: 'Dito Prasetyo',
            message:
                'Investasi terbaik yang pernah saya lakukan. Dalam 6 bulan saya bisa membangun aplikasi web sendiri dan langsung dapat klien freelance.',
            courseTypeName: 'Program Karir',
            rating: 5.0,
            date: '2026-02-20',
          ),
        ],
        faqs: [
          PublicFaq(
            id: 'faq1',
            question: 'Apakah saya perlu pengalaman programming sebelumnya?',
            answer:
                'Tidak perlu sama sekali! Program ini dirancang untuk pemula. Kami akan membimbing kamu dari dasar hingga mahir.',
          ),
          PublicFaq(
            id: 'faq2',
            question: 'Bagaimana metode pembayaran yang tersedia?',
            answer:
                'Kami menyediakan beberapa metode: pembayaran penuh, cicilan bulanan, atau pembayaran per sesi. Hubungi CS kami untuk detail lebih lanjut.',
          ),
          PublicFaq(
            id: 'faq3',
            question: 'Apakah ada garansi uang kembali?',
            answer:
                'Ya, kami memberikan garansi uang kembali 100% dalam 7 hari pertama jika kamu merasa program tidak sesuai ekspektasi.',
          ),
          PublicFaq(
            id: 'faq4',
            question: 'Sertifikat apa yang akan saya dapatkan?',
            answer:
                'Program Karir mendapatkan Sertifikat Peserta dan Sertifikat Kompetensi (setelah lulus uji kompetensi). Reguler mendapatkan Sertifikat Peserta.',
          ),
        ],
      );
}
