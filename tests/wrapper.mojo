from testing import testing


@value
struct MojoTest:
    """
    A utility struct for testing.
    """

    var test_name: String

    fn __init__(inout self, test_name: String):
        self.test_name = test_name
        print("# " + test_name)

    fn assert_true(self, cond: Bool, message: String):
        """
        Wraps testing.assert_true.
        """
        try:
            testing.assert_true(cond, message)
        except e:
            print(e)

    fn assert_equal(self, left: Int, right: Int):
        try:
            testing.assert_equal(left, right)
        except e:
            print(e)

    fn assert_equal(self, left: String, right: String):
        try:
            testing.assert_equal(left, right)
        except e:
            print(e)
