//
//  ViewController.m
//  clangInsertPile
//
//  Created by machao on 2021/10/20.
//

#import "ViewController.h"
#import <dlfcn.h>
#import <libkern/OSAtomicQueue.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                                    uint32_t *stop) {
  static uint64_t N;  // Counter for the guards.
  if (start == stop || *start) return;  // Initialize only once.
  printf("INIT: %p %p\n", start, stop);
  for (uint32_t *x = start; x < stop; x++)
    *x = ++N;  // Guards should start from 1.
}

void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
//    if (!*guard) return;  // Duplicate the guard check.

    void *PC = __builtin_return_address(0);
    
    Dl_info info;
    dladdr(PC, &info);
    
    printf("fname=%s \nfbase=%p \nsname=%s\nsaddr=%p \n",info.dli_fname,info.dli_fbase,info.dli_sname,info.dli_saddr);
    
    char PcDescr[1024];
    
    //__sanitizer_symbolize_pc(PC, "%p %F %L", PcDescr, sizeof(PcDescr));
    printf("guard: %p %x PC %s\n", guard, *guard, PcDescr);
    
    SymbolNode *node = malloc(sizeof(SymbolNode));
    
    *node = (SymbolNode){PC, NULL};
    
    OSAtomicEnqueue(&symboList, node, offsetof(SymbolNode, next));
}

- (void)testOCFunc{
    MABlock();
}

void (^MABlock)(void) = ^(void) {
    NSLog(@"block");
};

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    NSMutableArray<NSString *> * symbolNames = [NSMutableArray array];
    
    while (true) {
        
        //offsetof 就是针对某个结构体找到某个属性相对这个结构体的偏移量
        SymbolNode * node = OSAtomicDequeue(&symboList, offsetof(SymbolNode, next));
        
        if (node == NULL) break;
        
        Dl_info info;
        
        dladdr(node->pc, &info);
        
//        printf("%s \n",info.dli_sname);
        
        NSString * name = @(info.dli_sname);
        // 是否是OC方法
        BOOL isObjc = [name hasPrefix:@"+["] || [name hasPrefix:@"-["];
        //
        NSString * symbolName = isObjc ? name : [@"_" stringByAppendingString:name];
        
        if (![symbolNames containsObject:symbolName]) {
            [symbolNames addObject:symbolName];
        }
        
    }
    
    NSArray *symbolArray = [[symbolNames reverseObjectEnumerator] allObjects];
    
    NSLog(@"the symbolArray is %@", symbolArray);
    
}

//原子队列
static OSQueueHead symboList = OS_ATOMIC_QUEUE_INIT;

//定义符号结构体
typedef struct{
    void * pc;
    void * next;
} SymbolNode;

@end
