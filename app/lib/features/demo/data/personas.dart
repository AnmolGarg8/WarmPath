// allow-mock-file: guided demo, simulated and labelled

class SamplePersona {
  final String id;
  final String name;
  final String role;
  final String institution;
  final String department;
  final String batch;
  final String avatarInitials;
  final String bio;
  final List<String> skills;
  final List<String> offers;
  final String band; // 'Rising', 'Trusted', 'Top Rated', or 'N/A'
  final double rating;
  final int sessionCount;
  final int weeklyCapacity;
  final int remainingCapacity;
  final bool isOnline;
  final bool isOwnCollege;
  final String verificationLevel;

  const SamplePersona({
    required this.id,
    required this.name,
    required this.role,
    required this.institution,
    required this.department,
    required this.batch,
    required this.avatarInitials,
    required this.bio,
    required this.skills,
    required this.offers,
    this.band = 'Rising',
    this.rating = 4.0,
    this.sessionCount = 0,
    this.weeklyCapacity = 3,
    this.remainingCapacity = 3,
    this.isOnline = false,
    this.isOwnCollege = false,
    this.verificationLevel = 'verified',
  });
}

class DemoPersonas {
  // Student: Riya (sample) from Demo University
  static const SamplePersona studentRiya = SamplePersona(
    id: 'sample_student_riya',
    name: 'Riya (sample)',
    role: 'Student',
    institution: 'Demo University',
    department: 'Computer Science & Engineering',
    batch: 'Class of 2026',
    avatarInitials: 'RS',
    bio: '3rd year student passionate about distributed systems and machine learning. Seeking internship guidance and mock interviews.',
    skills: ['Python', 'SQL', 'FastAPI', 'Machine Learning', 'Data Analysis'],
    offers: [],
    band: 'N/A',
    rating: 0.0,
    sessionCount: 0,
    weeklyCapacity: 0,
    remainingCapacity: 0,
    isOnline: false,
    isOwnCollege: true,
    verificationLevel: 'verified',
  );

  // Own-college Giver: Arjun (sample alumnus) from Demo University
  static const SamplePersona giverArjun = SamplePersona(
    id: 'sample_giver_arjun',
    name: 'Arjun (sample)',
    role: 'Alumnus & Software Engineer',
    institution: 'Demo University',
    department: 'Computer Science & Engineering',
    batch: 'Class of 2021',
    avatarInitials: 'AS',
    bio: 'Backend systems engineer at Sample Tech Labs. Passionate about helping campus juniors with resume review and coding interviews.',
    skills: ['Python', 'SQL', 'PostgreSQL', 'Docker', 'System Design'],
    offers: ['Resume Review', 'Backend Architecture Guidance', 'Mock Coding Interview'],
    band: 'Rising',
    rating: 4.6,
    sessionCount: 8,
    weeklyCapacity: 3,
    remainingCapacity: 2,
    isOnline: true,
    isOwnCollege: true,
    verificationLevel: 'verified',
  );

  // Cross-college Giver 1: Meera (sample) from Sample Institute of Technology (Trusted Band)
  static const SamplePersona giverMeera = SamplePersona(
    id: 'sample_giver_meera',
    name: 'Meera (sample)',
    role: 'Lead Cloud Architect',
    institution: 'Sample Institute of Technology',
    department: 'Information Technology',
    batch: 'Class of 2018',
    avatarInitials: 'MS',
    bio: 'Specialized in microservices, AWS/GCP cloud platforms, and engineering mentorship for early career developers.',
    skills: ['System Design', 'Cloud Architecture', 'Kubernetes', 'Go', 'DevOps'],
    offers: ['Cloud Architecture Critique', 'Mock Systems Interview', 'Career Transition Mentorship'],
    band: 'Trusted',
    rating: 4.85,
    sessionCount: 22,
    weeklyCapacity: 4,
    remainingCapacity: 3,
    isOnline: false,
    isOwnCollege: false,
    verificationLevel: 'verified',
  );

  // Cross-college Giver 2: Dev (sample) from Sample Institute of Technology (Top Rated Band)
  static const SamplePersona giverDev = SamplePersona(
    id: 'sample_giver_dev',
    name: 'Dev (sample)',
    role: 'Founding AI Researcher & Director',
    institution: 'Sample Institute of Technology',
    department: 'Computer Science & Engineering',
    batch: 'Class of 2015',
    avatarInitials: 'DS',
    bio: 'Founder at Sample AI Studio. Guiding high-agency builders on ML research, startup roadmaps, and technical leadership.',
    skills: ['Machine Learning', 'Deep Learning', 'PyTorch', 'Startup Mentorship', 'LLM Engineering'],
    offers: ['AI/ML Research Guidance', 'Startup Pitch Critique', 'Executive Technical Mentorship'],
    band: 'Top Rated',
    rating: 4.95,
    sessionCount: 48,
    weeklyCapacity: 2,
    remainingCapacity: 1,
    isOnline: true,
    isOwnCollege: false,
    verificationLevel: 'verified',
  );

  // Hard Gate Candidate 1: Sanjay (sample) - Zero capacity this week
  static const SamplePersona giverSanjayZeroCapacity = SamplePersona(
    id: 'sample_giver_sanjay',
    name: 'Sanjay (sample)',
    role: 'Staff Infrastructure Engineer',
    institution: 'Demo University',
    department: 'Computer Science & Engineering',
    batch: 'Class of 2019',
    avatarInitials: 'SS',
    bio: 'Infrastructure specialist. Currently booked out for current weekly cycle.',
    skills: ['Python', 'Docker', 'Kubernetes'],
    offers: ['DevOps Roadmap'],
    band: 'Trusted',
    rating: 4.7,
    sessionCount: 15,
    weeklyCapacity: 2,
    remainingCapacity: 0, // Hard gate: 0 capacity
    isOnline: false,
    isOwnCollege: true,
    verificationLevel: 'verified',
  );

  // Hard Gate Candidate 2: Vikram (sample) - Unverified / restricted
  static const SamplePersona giverVikramUnverified = SamplePersona(
    id: 'sample_giver_vikram',
    name: 'Vikram (sample)',
    role: 'Guest Speaker',
    institution: 'Other Regional Academy',
    department: 'General Studies',
    batch: 'Class of 2022',
    avatarInitials: 'VS',
    bio: 'Pending verification credentials review.',
    skills: ['Python', 'Web Development'],
    offers: ['General Chat'],
    band: 'Rising',
    rating: 3.5,
    sessionCount: 1,
    weeklyCapacity: 2,
    remainingCapacity: 2,
    isOnline: false,
    isOwnCollege: false,
    verificationLevel: 'unverified', // Hard gate: unverified
  );

  // Sample Recruiter: Sarah (sample)
  static const SamplePersona recruiterSarah = SamplePersona(
    id: 'sample_recruiter_sarah',
    name: 'Sarah (sample)',
    role: 'University Talent Partner',
    institution: 'Sample Talent Network',
    department: 'Campus Recruitment',
    batch: 'Class of 2017',
    avatarInitials: 'ST',
    bio: 'Screening engineering talent for fast-growing technology programs.',
    skills: ['Resume Review', 'Interview Prep', 'Career Coaching'],
    offers: ['Early-Career Screening', 'Portfolio Feedback'],
    band: 'Top Rated',
    rating: 4.9,
    sessionCount: 30,
    weeklyCapacity: 5,
    remainingCapacity: 4,
    isOnline: true,
    isOwnCollege: false,
    verificationLevel: 'verified',
  );

  // Sample Moderator: Priya (sample)
  static const SamplePersona moderatorPriya = SamplePersona(
    id: 'sample_mod_priya',
    name: 'Priya (sample)',
    role: 'Campus Safety & Moderation Lead',
    institution: 'Demo University',
    department: 'Student Affairs & Trust Office',
    batch: 'Staff',
    avatarInitials: 'PM',
    bio: 'Reviewing flagged messages, payment bypass attempts, and community reports.',
    skills: ['Trust & Safety', 'Dispute Resolution', 'Campus Moderation'],
    offers: [],
    band: 'N/A',
    rating: 0.0,
    sessionCount: 0,
    weeklyCapacity: 0,
    remainingCapacity: 0,
    isOnline: true,
    isOwnCollege: true,
    verificationLevel: 'verified',
  );

  // Sample Institution Admin: Prof. Raman (sample)
  static const SamplePersona adminRaman = SamplePersona(
    id: 'sample_admin_raman',
    name: 'Prof. Raman (sample)',
    role: 'Dean of Student Affairs',
    institution: 'Demo University',
    department: 'Administration',
    batch: 'Faculty',
    avatarInitials: 'PR',
    bio: 'Overseeing institutional alumni network connections, seat allocations, and skill gap metrics.',
    skills: ['Institution Analytics', 'Alumni Relations', 'Student Welfare'],
    offers: [],
    band: 'N/A',
    rating: 0.0,
    sessionCount: 0,
    weeklyCapacity: 0,
    remainingCapacity: 0,
    isOnline: true,
    isOwnCollege: true,
    verificationLevel: 'verified',
  );

  static const List<SamplePersona> allGivers = [
    giverArjun,
    giverMeera,
    giverDev,
    giverSanjayZeroCapacity,
    giverVikramUnverified,
  ];

  static const List<String> approvedInstitutionDomains = [
    'demouniversity.edu',
    'sample.edu',
    'sampletech.edu',
  ];
}
