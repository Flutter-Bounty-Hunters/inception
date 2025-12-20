import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';

void main() {
  group('PieceTable', () {
    test('initial text loads correctly', () {
      final pt = PieceTable('hello');
      expect(pt.getText(), 'hello');
      expect(pt.length, 5);
    });

    test('insert at beginning', () {
      final pt = PieceTable('world');
      pt.insert(0, 'hello ');
      expect(pt.getText(), 'hello world');
    });

    test('insert at end', () {
      final pt = PieceTable('hello');
      pt.insert(5, ' world');
      expect(pt.getText(), 'hello world');
    });

    test('insert in the middle', () {
      final pt = PieceTable('helo world');
      pt.insert(2, 'l');
      expect(pt.getText(), 'hello world');
    });

    test('delete middle range', () {
      final pt = PieceTable('hello beautiful world');
      pt.delete(offset: 5, count: 10); // remove " beautiful"
      expect(pt.getText(), 'hello world');
    });

    test('delete at beginning', () {
      final pt = PieceTable('Say: hello');
      pt.delete(offset: 0, count: 5); // remove "Say: "
      expect(pt.getText(), 'hello');
    });

    test('delete at end', () {
      final pt = PieceTable('hello world!!!');
      pt.delete(offset: 11, count: 3); // remove !!!
      expect(pt.getText(), 'hello world');
    });

    test('delete entire contents', () {
      final pt = PieceTable('abc123');
      pt.delete(offset: 0, count: pt.length);
      expect(pt.getText(), '');
      expect(pt.length, 0);
    });

    test('insert after delete at same location', () {
      final pt = PieceTable('hello world');
      pt.delete(offset: 5, count: 1); // remove space
      pt.insert(5, ','); // insert comma
      expect(pt.getText(), 'hello,world');
    });

    test('multiple inserts create multiple pieces', () {
      final pt = PieceTable('A');
      pt.insert(1, 'B');
      pt.insert(2, 'C');
      pt.insert(3, 'D');
      pt.insert(4, 'E');
      expect(pt.getText(), 'ABCDE');
    });

    test('consecutive deletions across boundaries', () {
      final pt = PieceTable('hello wonderful world');
      pt.delete(offset: 5, count: 10); // delete " wonderful"
      pt.delete(offset: 5, count: 1); // delete space
      expect(pt.getText(), 'helloworld');
    });

    test('inserting into an empty document', () {
      final pt = PieceTable('');
      pt.insert(0, 'hello');
      expect(pt.getText(), 'hello');
    });

    test('delete range spanning multiple pieces', () {
      final pt = PieceTable('hello world');
      pt.insert(5, ' beautiful');
      pt.insert(5, ' very');

      // doc = "hello very beautiful world"
      pt.delete(offset: 5, count: 11);

      expect(pt.getText(), 'helloiful world');
    });

    test('insert then delete repeatedly (stress-lite)', () {
      final pt = PieceTable('0123456789');

      for (int i = 0; i < 5; i++) {
        pt.insert(5, 'X');
        pt.delete(offset: 5, count: 1);
      }

      expect(pt.getText(), '0123456789');
    });

    test('insert long text chunk', () {
      final pt = PieceTable('hello');
      final longText = 'x' * 1000;
      pt.insert(5, longText);
      expect(pt.getText(), 'hello$longText');
    });

    test('delete inside inserted text block', () {
      final pt = PieceTable('hello');
      pt.insert(5, ' beautiful world');
      pt.delete(offset: 7, count: 9);
      expect(pt.getText(), 'hello bworld');
    });

    test('insert at every boundary', () {
      final pt = PieceTable('abcd');
      pt.insert(0, 'x');
      pt.insert(2, 'y');
      pt.insert(pt.length, 'z');
      expect(pt.getText(), 'xaybcdz');
    });

    test('delete that splits inserted piece', () {
      final pt = PieceTable('hello');
      pt.insert(5, 'ABCDE');
      pt.delete(offset: 7, count: 2); // delete "CD" inside the inserted block
      expect(pt.getText(), 'helloABE');
    });

    test('mixed operations simulate typing', () {
      final pt = PieceTable('');

      pt.insert(0, 'h');
      pt.insert(1, 'e');
      pt.insert(2, 'l');
      pt.insert(3, 'l');
      pt.insert(4, 'o');

      pt.delete(offset: 4, count: 1); // remove last "o"
      pt.insert(4, 'o');
      pt.insert(5, ' world');

      expect(pt.getText(), 'hello world');
    });
  });
}
