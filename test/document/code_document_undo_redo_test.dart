import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inception/inception.dart';

import 'test_tools.dart';

void main() {
  group('CodeDocument undo/redo – basic', () {
    test('insert and undo (single action)', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), '');
        doc.insert(0, 'hello');
        async.elapse(CodeDocument.batchInterval); // end batch

        expect(doc.text, 'hello');
        expect(doc.canUndo, true);
        expect(doc.canRedo, false);

        doc.undo();
        expect(doc.text, '');
        expect(doc.canUndo, false);
        expect(doc.canRedo, true);

        doc.redo();
        expect(doc.text, 'hello');
        expect(doc.canUndo, true);
        expect(doc.canRedo, false);
      });
    });

    test('delete and undo', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'abcdef');
        doc.delete(offset: 2, count: 3); // delete cde
        expect(doc.text, 'abf');

        async.elapse(CodeDocument.batchInterval);

        doc.undo();
        expect(doc.text, 'abcdef');

        doc.redo();
        expect(doc.text, 'abf');
      });
    });

    test('undo/redo multiple independent steps', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), '');

        doc.insert(0, 'a');
        async.elapse(CodeDocument.batchInterval);

        doc.insert(1, 'b');
        async.elapse(CodeDocument.batchInterval);

        doc.insert(2, 'c');
        async.elapse(CodeDocument.batchInterval);

        expect(doc.text, 'abc');

        doc.undo();
        expect(doc.text, 'ab');

        doc.undo();
        expect(doc.text, 'a');

        doc.undo();
        expect(doc.text, '');

        expect(doc.canUndo, false);

        doc.redo();
        expect(doc.text, 'a');

        doc.redo();
        expect(doc.text, 'ab');

        doc.redo();
        expect(doc.text, 'abc');

        expect(doc.canRedo, false);
      });
    });
  });

  group('CodeDocument undo/redo – batching behavior', () {
    test('typing letters quickly batches into one undo step', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), '');

        doc.insert(0, 'h');
        async.elapse(const Duration(milliseconds: 100));

        doc.insert(1, 'e');
        async.elapse(const Duration(milliseconds: 100));

        doc.insert(2, 'l');
        async.elapse(const Duration(milliseconds: 100));

        doc.insert(3, 'l');
        async.elapse(const Duration(milliseconds: 100));

        doc.insert(4, 'o');

        // Now end the batch
        async.elapse(CodeDocument.batchInterval);

        expect(doc.text, 'hello');
        expect(doc.canUndo, true);

        // One undo removes all 5 inserts
        doc.undo();
        expect(doc.text, '');
      });
    });

    test('pause between letters ends batch (two undo steps)', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), '');

        doc.insert(0, 'h');
        async.elapse(CodeDocument.batchInterval); // batch ends

        doc.insert(1, 'i');
        async.elapse(CodeDocument.batchInterval); // batch ends

        expect(doc.text, 'hi');

        doc.undo(); // undo 'i'
        expect(doc.text, 'h');

        doc.undo(); // undo 'h'
        expect(doc.text, '');
      });
    });

    test('delete batching: holding delete key batches deletes', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'abcdef');

        doc.delete(offset: 5, count: 1); // delete f
        async.elapse(const Duration(milliseconds: 50));

        doc.delete(offset: 4, count: 1); // delete e
        async.elapse(const Duration(milliseconds: 50));

        doc.delete(offset: 3, count: 1); // delete d
        async.elapse(CodeDocument.batchInterval); // end batch

        expect(doc.text, 'abc');

        doc.undo(); // restore d,e,f
        expect(doc.text, 'abcdef');
      });
    });

    test('insert → delete should break batch (different action types)', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'abc');

        doc.insert(3, 'X'); // abcX
        expect(doc.text, 'abcX');
        async.elapse(const Duration(milliseconds: 100));

        doc.delete(offset: 1, count: 1); // remove b → aXc
        expect(doc.text, 'acX');
        async.elapse(CodeDocument.batchInterval);

        doc.undo(); // undo delete
        expect(doc.text, 'abcX');

        doc.undo(); // undo insert
        expect(doc.text, 'abc');
      });
    });

    test('overlapping batches: quick typing, pause, more typing', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), '');

        // First batch: type 'h', 'e', 'l' quickly
        doc.insert(0, 'h');
        async.elapse(const Duration(milliseconds: 100));

        doc.insert(1, 'e');
        async.elapse(const Duration(milliseconds: 100));

        doc.insert(2, 'l');
        async.elapse(CodeDocument.batchInterval); // first batch ends

        // Second batch: pause long enough, then type 'l', 'o'
        async.elapse(const Duration(milliseconds: 800)); // simulate pause longer than batch interval

        doc.insert(3, 'l');
        async.elapse(const Duration(milliseconds: 100));

        doc.insert(4, 'o');
        async.elapse(CodeDocument.batchInterval); // second batch ends

        expect(doc.text, 'hello');
        expect(doc.canUndo, true);

        // Undo: should remove the second batch ('lo')
        doc.undo();
        expect(doc.text, 'hel');

        // Undo again: should remove the first batch ('hel')
        doc.undo();
        expect(doc.text, '');

        // Redo: first batch restored
        doc.redo();
        expect(doc.text, 'hel');

        // Redo: second batch restored
        doc.redo();
        expect(doc.text, 'hello');
      });
    });
  });

  group('CodeDocument undo/redo – edge cases', () {
    test('undo when no history does nothing', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'x');
        expect(doc.canUndo, false);

        doc.undo();
        expect(doc.text, 'x');
      });
    });

    test('redo when no redo history does nothing', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'x');
        expect(doc.canRedo, false);

        doc.redo();
        expect(doc.text, 'x');
      });
    });

    test('inserts at start, end, middle are separate steps', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'abc');

        doc.insert(0, 'X'); // Xabc
        async.elapse(CodeDocument.batchInterval);

        doc.insert(4, 'Y'); // XabcY
        async.elapse(CodeDocument.batchInterval);

        doc.insert(2, 'Z'); // XaZbcY
        async.elapse(CodeDocument.batchInterval);

        expect(doc.text, 'XaZbcY');

        doc.undo();
        expect(doc.text, 'XabcY');

        doc.undo();
        expect(doc.text, 'Xabc');

        doc.undo();
        expect(doc.text, 'abc');

        doc.redo();
        expect(doc.text, 'Xabc');

        doc.redo();
        expect(doc.text, 'XabcY');

        doc.redo();
        expect(doc.text, 'XaZbcY');
      });
    });

    test('delete entire document and undo', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'hello\nworld');
        doc.delete(offset: 0, count: doc.length);
        async.elapse(CodeDocument.batchInterval);

        expect(doc.text, '');

        doc.undo();
        expect(doc.text, 'hello\nworld');

        doc.redo();
        expect(doc.text, '');
      });
    });

    test('multi-line insert/delete with undo/redo', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'a\nb\nc');

        doc.insert(4, '\nX\nY');
        async.elapse(CodeDocument.batchInterval);
        expect(doc.text, 'a\nb\n\nX\nYc');

        doc.delete(offset: 2, count: 3);
        async.elapse(CodeDocument.batchInterval);
        expect(doc.text, 'a\nX\nYc');

        doc.undo();
        expect(doc.text, 'a\nb\n\nX\nYc');

        doc.undo();
        expect(doc.text, 'a\nb\nc');
      });
    });

    test('undo/redo after consecutive edits with batching between', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'abc');

        doc.insert(3, '123'); // abc123
        async.elapse(CodeDocument.batchInterval);

        doc.delete(offset: 1, count: 2); // a123
        async.elapse(CodeDocument.batchInterval);

        expect(doc.text, 'a123');

        doc.undo(); // undo delete → abc123
        expect(doc.text, 'abc123');

        doc.undo(); // undo insert → abc
        expect(doc.text, 'abc');

        doc.redo(); // redo insert
        expect(doc.text, 'abc123');

        doc.redo(); // redo delete
        expect(doc.text, 'a123');
      });
    });
  });

  group('CodeDocument undo/redo – line/column correctness', () {
    test('offsetToLineColumn stays correct after undo/redo', () {
      fakeAsync((async) {
        final doc = CodeDocument(FakeLexer(), 'a\nb\nc');

        doc.insert(1, 'X\nY');
        async.elapse(CodeDocument.batchInterval);

        expect(doc.text, 'aX\nY\nb\nc');
        expect(doc.offsetToLineColumn(0), (0, 0));
        expect(doc.offsetToLineColumn(3), (1, 0));
        expect(doc.offsetToLineColumn(5), (2, 0));

        doc.undo();
        expect(doc.text, 'a\nb\nc');
        expect(doc.offsetToLineColumn(0), (0, 0));
        expect(doc.offsetToLineColumn(2), (1, 0));
        expect(doc.offsetToLineColumn(4), (2, 0));

        doc.redo();
        expect(doc.text, 'aX\nY\nb\nc');
        expect(doc.offsetToLineColumn(0), (0, 0));
        expect(doc.offsetToLineColumn(3), (1, 0));
        expect(doc.offsetToLineColumn(5), (2, 0));
      });
    });
  });
}
