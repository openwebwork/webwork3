import { Course, ParseableCourse, UserCourse } from 'src/common/models/courses';

describe('Test Course Models', () => {

	const default_course = {
		course_id: 0,
		course_name: 'Arithmetic',
		visible: true,
		course_dates: { start: 0, end: 0 }
	};

	describe('Creation of a Course', () => {

		test('Create a Valid Course', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			expect(course).toBeInstanceOf(Course);
			expect(course.toObject()).toStrictEqual(default_course);
			expect(course.isValid()).toBe(true);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const course_fields = ['course_id', 'course_name', 'visible', 'course_dates'];
			const course = new Course({ course_name: 'Arithmetic' });

			expect(course.all_field_names.sort()).toStrictEqual(course_fields.sort());
			expect(course.param_fields.sort()).toStrictEqual(['course_dates']);
			expect(Course.ALL_FIELDS.sort()).toStrictEqual(course_fields.sort());
		});

		test('Check that cloning works', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			expect(course.clone().toObject()).toStrictEqual(default_course);
			expect(course.clone()).toBeInstanceOf(Course);
		});

	});

	describe('Updating a course', () => {
		test('set fields of a course', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			course.course_id = 5;
			expect(course.course_id).toBe(5);

			course.course_name = 'Geometry';
			expect(course.course_name).toBe('Geometry');

			course.visible = false;
			expect(course.visible).toBe(false);
			expect(course.isValid()).toBe(true);

		});

		test('set fields of a course using the set method', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			course.set({
				course_id: 5,
				course_name: 'Geometry',
				visible: false
			});
			expect(course.course_id).toBe(5);
			expect(course.course_name).toBe('Geometry');
			expect(course.visible).toBe(false);
			expect(course.isValid()).toBe(true);
		});
	});

	describe('Checking the course dates', () => {
		test('checking for valid course dates', () => {
			const course = new Course({
				course_name: 'Arithemetic',
				course_dates: { start: 100, end: 100 }
			});
			expect(course.course_dates.isValid()).toBe(true);
			expect(course.isValid()).toBe(true);
		});
	});

	describe('Checking valid and invalid creation parameters.', () => {

		test('Parsing of undefined and null values', () => {
			const course1 = new Course({ course_name: 'Arithmetic' });
			const course2 = new Course({ course_name: 'Arithmetic', course_id: undefined });
			expect(course1).toStrictEqual(course2);

			// the following allow to pass in non-valid parameters for testing
			const params = { course_name: 'Arithmetic', course_id: null };
			const course3 = new Course(params as unknown as ParseableCourse);
			expect(course1).toStrictEqual(course3);
		});

		test('Create a course with invalid fields', () => {
			const c1 = new Course({ course_name: 'Arithmetic', course_id: -1 });
			expect(c1.isValid()).toBe(false);

			const c2 = new Course({ course_name: '', course_id: 0 });
			expect(c2.isValid()).toBe(false);
		});

		test('Create a course with invalid dates', () => {
			const c1 = new Course({
				course_name: 'Arithmetic',
				course_dates: { start: 100, end: 0 }
			});
			expect(c1.isValid()).toBe(false);
		});
	});

	const default_user_course = {
		course_id: 0,
		user_id: 0,
		course_name: '',
		username: '',
		visible: true,
		role: 'UNKNOWN',
		course_dates : { start: 0, end: 0 }
	};

	// Note: the role is not tested here because the defined roles are now in the database
	// therefore, they are tested in tests/store/courses.spec.ts.

	describe('Creating a User Course', () => {
		test('Create a Valid Course', () => {
			const user_course = new UserCourse();
			expect(user_course).toBeInstanceOf(UserCourse);
			expect(user_course.toObject()).toStrictEqual(default_user_course);
			// The user course is not valid because the course name and username are empty strings
			expect(user_course.isValid()).toBe(false);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const user_course_fields = ['course_id', 'user_id', 'course_name', 'username',
				'visible', 'role', 'course_dates'];
			const user_course = new UserCourse();
			expect(user_course.all_field_names.sort()).toStrictEqual(user_course_fields.sort());
			expect(UserCourse.ALL_FIELDS.sort()).toStrictEqual(user_course_fields.sort());
			expect(user_course.param_fields).toStrictEqual(['course_dates']);
		});

		test('Check that cloning works', () => {
			const user_course = new UserCourse();
			expect(user_course.clone().toObject()).toStrictEqual(default_user_course);
			expect(user_course.clone()).toBeInstanceOf(UserCourse);
		});
	});

	describe('Updating a UserCourse', () => {
		test('set fields of a user course', () => {
			const user_course = new UserCourse({ course_name: 'Arithmetic' });
			user_course.course_id = 5;
			expect(user_course.course_id).toBe(5);

			user_course.course_name = 'Geometry';
			expect(user_course.course_name).toBe('Geometry');

			user_course.visible = false;
			expect(user_course.visible).toBe(false);

			user_course.username = 'homer';
			expect(user_course.username).toBe('homer');

			user_course.role = 'student';
			expect(user_course.role).toBe('STUDENT');

			expect(user_course.isValid()).toBe(true);
		});
	});

	describe('Checking valid and invalid creation parameters.', () => {
		test('Parsing of undefined and null values', () => {
			const course1 = new UserCourse({ course_name: 'Arithmetic' });
			const course2 = new UserCourse({
				course_name: 'Arithmetic',
				user_id: undefined,
				course_id: undefined
			});
			expect(course1).toStrictEqual(course2);

			// the following allow to pass in non-valid parameters for testing
			const params = { course_name: 'Arithmetic', course_id: null };
			const course3 = new UserCourse(params as unknown as ParseableCourse);
			expect(course1).toStrictEqual(course3);
		});

		test('Create a course with invalid fields', () => {
			const c1 = new UserCourse({ course_name: 'Arithmetic', username: 'homer', role: 'student' });
			expect(c1.isValid()).toBe(true);

			c1.course_name = '';
			expect(c1.isValid()).toBe(false);

			c1.set({ course_name: 'Arithmetic', user_id: -1 });
			expect(c1.isValid()).toBe(false);

			c1.set({ user_id: 10, course_id: -1 });
			expect(c1.isValid()).toBe(false);

			c1.course_id = 10;
			expect(c1.isValid()).toBe(true);

			c1.username = '';
			expect(c1.isValid()).toBe(false);

			c1.username = 'invalid user';
			expect(c1.isValid()).toBe(false);

			c1.username = 'homer@msn.com';
			expect(c1.isValid()).toBe(true);

		});

		test('Create a user course with invalid dates', () => {
			const c1 = new UserCourse({
				course_name: 'Arithmetic',
				username: 'homer',
				role: 'student',
				course_dates: { start: 100, end: 200 }
			});
			expect(c1.isValid()).toBe(true);

			c1.setDates({ start: 100, end: 0 });
			expect(c1.isValid()).toBe(false);
		});
	});
});
