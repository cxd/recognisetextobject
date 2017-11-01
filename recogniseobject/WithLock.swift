//
//  WithLock.swift
//  recogniseobject
//


import Foundation


protocol WithLock {
    /**
     Internal lock used to prevent multiple batches queueing.
     Note a queue construct would be suitable to use in queuing batches.
     **/
    var lockObj:NSLock { get }
    
    /**
     wrap a function T -> S as an exclusive locking operation returning (T) -> S?
     **/
    func withLock<T,S>(_ fn:@escaping(T) -> S) -> (T) -> S?
    
    /**
     given an action that returns S wrap it in an exclusive locking operation and return S?
     **/
    func withLock<S>(_ fn:@escaping() -> S) -> () -> S?
    
    /**
     wrap an action () -> Void as an exclusive locking operation returning void.
     **/
    func withLock(_ fn:@escaping() -> Void) -> () -> Void
}

extension WithLock {
    
    func withLock<T,S>(_ fn:@escaping (T) -> S) -> (T) -> S? {
        return { (_ inArg:T) in
            if self.lockObj.try() {
                let result = try? fn(inArg)
                self.lockObj.unlock()
                return result
            }
            return nil
        }
    }
    
    func withLock<S>(_ fn:@escaping () -> S) -> () -> S? {
        return { () in
            if self.lockObj.try() {
                let result = try? fn()
                self.lockObj.unlock()
                return result
            }
            return nil
        }
    }
    
    func withLock(_ fn:@escaping () -> Void) -> () -> Void {
        return { () in
            if self.lockObj.try() {
                do { try fn() } catch {}
                self.lockObj.unlock()
            }
        }
    }
}
