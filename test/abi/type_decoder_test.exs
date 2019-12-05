defmodule ABI.TypeDecoderTest do
  use ExUnit.Case, async: true

  doctest ABI.TypeDecoder

  alias ABI.TypeDecoder
  alias ABI.TypeEncoder

  describe "decode/2 '{:int, size}' type" do
    test "successfully decodes positives and negatives integers" do
      positive_int = "000000000000000000000000000000000000000000000000000000000000002a"
      negative_int = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd8f1"
      result_to_decode = Base.decode16!(positive_int <> negative_int, case: :lower)

      selector = %ABI.FunctionSelector{
        function: "baz",
        types: [
          {:int, 8},
          {:int, 256}
        ],
        returns: :int
      }

      assert ABI.TypeDecoder.decode(result_to_decode, selector) == [42, -9999]
    end
  end

  describe "decode/2 and encode/2 parity" do
    test "with string data" do
      types = [:string]
      result = ["dave"]
      assert result == TypeEncoder.encode(result, types) |> TypeDecoder.decode(types)
    end

    test "with dynamic array data" do
      types = [{:array, :address}]
      result = [[]]
      assert result == TypeEncoder.encode(result, types) |> TypeDecoder.decode(types)

      types = [{:array, :address}]
      result = [[<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 35>>]]
      assert result == TypeEncoder.encode(result, types) |> TypeDecoder.decode(types)
    end

    test "with dynamic array data not at the beginning of types" do
      types = [:bool, {:array, :address}]
      result = [true, []]
      assert result == TypeEncoder.encode(result, types) |> TypeDecoder.decode(types)

      result = [true, [<<1::160>>]]
      assert result == TypeEncoder.encode(result, types) |> TypeDecoder.decode(types)
    end

    test "with a fixed-length array of dynamic data" do
      types = [{:array, :string, 3}]
      result = [["foo", "bar", "baz"]]
      assert result == TypeEncoder.encode(result, types) |> TypeDecoder.decode(types)
    end

    test "with multiple types" do
      types = [
        {:uint, 256},
        {:array, {:uint, 32}},
        {:bytes, 10},
        :bytes
      ]

      result = [0x123, [0x456, 0x789], "1234567890", "Hello, world!"]
      assert result == TypeEncoder.encode(result, types) |> TypeDecoder.decode(types)
    end

    test "with dynamic tuple" do
      types = [{:tuple, [:bytes, {:uint, 256}, :string]}]
      result = [{"dave", 0x123, "Hello, world!"}]
      assert result == TypeEncoder.encode(result, types) |> TypeDecoder.decode(types)
    end
  end

  describe "with fixed binary values" do
    # for test cases taken from solidity ABI docs go to next `describe`
    test "with static tuple" do
      types = [{:tuple, [{:uint, 256}, {:bytes, 10}]}]

      data =
        """
        0000000000000000000000000000000000000000000000000000000000000123
        3132333435363738393000000000000000000000000000000000000000000000
        """
        |> encode_multiline_string()

      assert TypeDecoder.decode(data, types) == [{0x123, "1234567890"}]
      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end

    test "with a fixed-length array of static data" do
      types = [{:array, {:uint, 256}, 6}]

      data =
        """
        0000000000000000000000000000000000000000000000000000000000000007
        0000000000000000000000000000000000000000000000000000000000000003
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000005
        """
        |> encode_multiline_string()

      assert TypeDecoder.decode(data, types) == [[7, 3, 0, 0, 0, 5]]
      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end

    test "with the output of an executed contract" do
      types = [
        {:array, {:uint, 256}, 6},
        :bool,
        {:array, {:uint, 256}, 24},
        {:array, :bool, 24},
        {:uint, 256},
        {:uint, 256},
        {:uint, 256},
        {:uint, 256},
        :string
      ]

      data =
        """
        0000000000000000000000000000000000000000000000000000000000000007
        0000000000000000000000000000000000000000000000000000000000000003
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000005
        0000000000000000000000000000000000000000000000000000000000000001
        00000000000000000000000000000000000000000000012413b856370914a000
        00000000000000000000000000000000000000000000012413b856370914a000
        00000000000000000000000000000000000000000000000053444835ec580000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000003e73362871420000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000001212f67eff9a8ac801a
        0000000000000000000000000000000000000000000001212f67eff9a8ac8010
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000009
        436172746167656e610000000000000000000000000000000000000000000000
        """
        |> encode_multiline_string()

      expected = [
        [7, 3, 0, 0, 0, 5],
        true,
        [
          0x12413B856370914A000,
          0x12413B856370914A000,
          0x53444835EC580000,
          0,
          0x3E73362871420000,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0
        ],
        [
          true,
          true,
          true,
          false,
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false
        ],
        0x1212F67EFF9A8AC801A,
        0x1212F67EFF9A8AC8010,
        1,
        1,
        "Cartagena"
      ]

      assert TypeDecoder.decode(data, types) == expected
      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end

    test "simple non-trivial dynamic type offset" do
      types = [{:uint, 32}, :bytes]

      data =
        """
        0000000000000000000000000000000000000000000000000000000000000123
        0000000000000000000000000000000000000000000000000000000000000040
        000000000000000000000000000000000000000000000000000000000000000d
        48656c6c6f2c20776f726c642100000000000000000000000000000000000000
        """
        |> encode_multiline_string()

      assert [0x123, "Hello, world!"] == TypeDecoder.decode(data, types)
      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end
  end

  describe "with examples from solidity docs" do
    # https://solidity.readthedocs.io/en/v0.5.13/abi-spec.html

    test "baz example" do
      types = [{:uint, 32}, :bool]

      data =
        """
        0000000000000000000000000000000000000000000000000000000000000045
        0000000000000000000000000000000000000000000000000000000000000001
        """
        |> encode_multiline_string()

      assert [69, true] == TypeDecoder.decode(data, types)
      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end

    test "bar example" do
      types = [{:array, {:bytes, 3}, 2}]

      data =
        """
        6162630000000000000000000000000000000000000000000000000000000000
        6465660000000000000000000000000000000000000000000000000000000000
        """
        |> encode_multiline_string()

      assert [["abc", "def"]] == TypeDecoder.decode(data, types)
      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end

    test "sam example" do
      types = [:bytes, :bool, {:array, {:uint, 32}}]

      data =
        """
        0000000000000000000000000000000000000000000000000000000000000060
        0000000000000000000000000000000000000000000000000000000000000001
        00000000000000000000000000000000000000000000000000000000000000a0
        0000000000000000000000000000000000000000000000000000000000000004
        6461766500000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000003
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000002
        0000000000000000000000000000000000000000000000000000000000000003
        """
        |> encode_multiline_string()

      assert ["dave", true, [1, 2, 3]] == TypeDecoder.decode(data, types)
      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end

    test "g example" do
      # o_O, nested dynamic arrays
      types = [{:array, {:array, {:uint, 256}}}, {:array, :string}]

      data =
        """
        0000000000000000000000000000000000000000000000000000000000000040
        0000000000000000000000000000000000000000000000000000000000000140
        0000000000000000000000000000000000000000000000000000000000000002
        0000000000000000000000000000000000000000000000000000000000000040
        00000000000000000000000000000000000000000000000000000000000000a0
        0000000000000000000000000000000000000000000000000000000000000002
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000002
        0000000000000000000000000000000000000000000000000000000000000001
        0000000000000000000000000000000000000000000000000000000000000003
        0000000000000000000000000000000000000000000000000000000000000003
        0000000000000000000000000000000000000000000000000000000000000060
        00000000000000000000000000000000000000000000000000000000000000a0
        00000000000000000000000000000000000000000000000000000000000000e0
        0000000000000000000000000000000000000000000000000000000000000003
        6f6e650000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000003
        74776f0000000000000000000000000000000000000000000000000000000000
        0000000000000000000000000000000000000000000000000000000000000005
        7468726565000000000000000000000000000000000000000000000000000000
        """
        |> encode_multiline_string()

      assert [[[1, 2], [3]], ["one", "two", "three"]] == TypeDecoder.decode(data, types)
      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end

    test "use of dynamic types example" do
      types = [{:uint, 32}, {:array, {:uint, 32}}, {:bytes, 10}, :bytes]

      data =
        """
        0000000000000000000000000000000000000000000000000000000000000123
        0000000000000000000000000000000000000000000000000000000000000080
        3132333435363738393000000000000000000000000000000000000000000000
        00000000000000000000000000000000000000000000000000000000000000e0
        0000000000000000000000000000000000000000000000000000000000000002
        0000000000000000000000000000000000000000000000000000000000000456
        0000000000000000000000000000000000000000000000000000000000000789
        000000000000000000000000000000000000000000000000000000000000000d
        48656c6c6f2c20776f726c642100000000000000000000000000000000000000
        """
        |> encode_multiline_string()

      assert [0x123, [0x456, 0x789], "1234567890", "Hello, world!"] ==
               TypeDecoder.decode(data, types)

      assert data == data |> TypeDecoder.decode(types) |> TypeEncoder.encode(types)
    end
  end

  defp encode_multiline_string(data) do
    data
    |> String.split("\n", trim: true)
    |> Enum.join()
    |> Base.decode16!(case: :mixed)
  end
end
