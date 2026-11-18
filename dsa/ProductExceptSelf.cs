namespace ConsoleApp1
{
    internal class Program
    {
        static void Main(string[] args)
        {
            int[] arr =new int[] {1,2,3,4};

            int[] res = ProductExceptSelf2(arr);
            foreach(int x in res)
            {
                Console.Write($"{x} ");
            }
        }
        // 5.1 PREFIX AND SUFFIX
        public static int[] ProductExceptSelf(int[] nums)
        {
            // Space Complexcity = O(n)
            // Time  Complexcity = O(n)

            int n = nums.Length;
            int[] prefix = new int[n];
            prefix[0] = nums[0];

            for (int i = 1; i < n; i++)
            {
                prefix[i] = nums[i] * prefix[i - 1];
            }

            int[] suffix = new int[n];
            suffix[n - 1] = nums[n - 1];
            for (int i = n - 2; i >= 0; i--)
            {
                suffix[i] = nums[i] * suffix[i + 1];
            }

            nums[0] = suffix[1];
            nums[n - 1] = prefix[n - 2];

            for (int i = 1; i < n - 1; i++)
            {
                nums[i] = prefix[i - 1] * suffix[i + 1];
            }
            return nums;




            // 2  3  5   0
            // 2  6  30  0       // prefix product
            // 0  0  0   0      // suffix product

            // 0  0  0  30  // answer
        }

        // 5.2 Optimized for Space
        public static int[] ProductExceptSelf2(int[] nums)
        {
            // Space Complexcity = O(1)
            // Time  Complexcity = O(n)


            int[] result = new int[nums.Length];
            result[0] = 1;

            for (int i = 1; i < nums.Length; i++)
                result[i] = result[i - 1] * nums[i - 1];

            int suffix = 1;

            for (int i = nums.Length - 1; i >= 0; i--)
            {
                result[i] *= suffix;
                suffix *= nums[i];
            }
            return result;
        }
    }
}
