///<summary>Lock-free containers. Part of the OmniThreadLibrary project.</summary>
///<author>Primoz Gabrijelcic, GJ</author>
///<license>
///This software is distributed under the BSD license.
///
///Copyright (c) 2008, Primoz Gabrijelcic
///All rights reserved.
///
///Redistribution and use in source and binary forms, with or without modification,
///are permitted provided that the following conditions are met:
///- Redistributions of source code must retain the above copyright notice, this
///  list of conditions and the following disclaimer.
///- Redistributions in binary form must reproduce the above copyright notice,
///  this list of conditions and the following disclaimer in the documentation
///  and/or other materials provided with the distribution.
///- The name of the Primoz Gabrijelcic may not be used to endorse or promote
///  products derived from this software without specific prior written permission.
///
///THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
///ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
///WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
///DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
///ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
///(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
///LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
///ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
///(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
///SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
///</license>
///<remarks><para>
///   Author            : Primoz Gabrijelcic, GJ
///   Creation date     : 2008-07-13
///   Last modification : dt
///   Version           : 0.3
///</para><para>
///   History:
///     0.3: 2008-07-16
///       - TOmniBaseContainer made abstract.
///       - Added TOmniBaseStack class which encapsulates base stack functionality.
///       - TOmniQueue renamed to TOmniQueue.
///       - Added TOmniBaseQueue class which encapsulates base queue functionality.
///     0.2: 2008-07-15
///       - Fixed a bug in PopLink.
///       - Implemented Empty method in both containers.
///</para></remarks>

unit OtlContainers;

interface

uses
  OtlCommon;

type
  {:Lock-free, single writer, single reader, size-limited stack.
  }
  IOmniStack = interface ['{F4C57327-18A0-44D6-B95D-2D51A0EF32B4}']
    procedure Empty;
    procedure Initialize(numElements, elementSize: integer);
    function  Pop(var value): boolean;
    function  Push(const value): boolean;
    function  IsEmpty: boolean;
    function  IsFull: boolean;
  end; { IOmniStack }

  {:Lock-free, single writer, single reader ring buffer.
  }
  IOmniRingBuffer = interface ['{AE6454A2-CDB4-43EE-9F1B-5A7307593EE9}']
    procedure Empty;
    procedure Initialize(numElements, elementSize: integer);
    function  Enqueue(const value): boolean;
    function  Dequeue(var value): boolean;
    function  IsEmpty: boolean;
    function  IsFull: boolean;
  end; { IOmniRingBuffer }

  IOmniNotifySupport = interface ['{E5FFC739-669A-4931-B0DC-C5005A94A08B}']
    function  GetNewDataEvent: THandle;
  //
    procedure Signal;
    property NewDataEvent: THandle read GetNewDataEvent;
  end; { IOmniNotifySupport }

  POmniLinkedData = ^TOmniLinkedData;
  TOmniLinkedData = packed record
    Next: POmniLinkedData;
    Data: byte; //user data, variable size
  end; { TLinkedOmniData }

  TOmniHeadAndSpin = packed record
    Head: POmniLinkedData;
    Spin: cardinal;
  end; { TOmniHeadAndSpin }

  TOmniBaseContainer = class abstract(TInterfacedObject)
  strict protected
    obcBuffer      : pointer;
    obcElementSize : integer;
    obcNumElements : integer;
    obcPublicChain : TOmniHeadAndSpin;
    obcRecycleChain: TOmniHeadAndSpin;
    class function  InvertOrder(chainHead: POmniLinkedData): POmniLinkedData; static;
    class function  PopLink(var chain: TOmniHeadAndSpin): POmniLinkedData; static;
    class procedure PushLink(const link: POmniLinkedData; var chain: TOmniHeadAndSpin); static;
    class function  UnlinkAll(var chain: TOmniHeadAndSpin): POmniLinkedData; static;
  public
    destructor  Destroy; override;
    procedure Empty; virtual;
    procedure Initialize(numElements, elementSize: integer); virtual;
    function  IsEmpty: boolean; virtual;
    function  IsFull: boolean; virtual;
    property ElementSize: integer read obcElementSize;
    property NumElements: integer read obcNumElements;
  end; { TOmniBaseContainer }

  TOmniBaseStack = class(TOmniBaseContainer)
  public
    function  Pop(var value): boolean; virtual;
    function  Push(const value): boolean; virtual;
  end; { TOmniBaseStack }

  TOmniContainerOption = (coEnableMonitor, coEnableNotify);
  TOmniContainerOptions = set of TOmniContainerOption;

  TOmniStack = class(TOmniBaseStack, IOmniStack, IOmniNotifySupport, IOmniMonitorSupport)
  strict private
    osMonitorSupport: IOmniMonitorSupport;
    osNotifySupport : IOmniNotifySupport;
    osOptions       : TOmniContainerOptions;
  public
    constructor Create(numElements, elementSize: integer;
      options: TOmniContainerOptions = [coEnableMonitor, coEnableNotify]);
    function Pop(var value): boolean; override;
    function Push(const value): boolean; override; 
    property MonitorSupport: IOmniMonitorSupport read osMonitorSupport implements IOmniMonitorSupport;
    property NotifySupport: IOmniNotifySupport read osNotifySupport implements IOmniNotifySupport;
    property Options: TOmniContainerOptions read osOptions;
  end; { TOmniStack }

  TOmniBaseQueue = class(TOmniBaseContainer)
  strict protected
    obqDequeuedMessages: TOmniHeadAndSpin;
  public
    constructor Create;
    function  Dequeue(var value): boolean; virtual;
    procedure Empty; override;
    function  Enqueue(const value): boolean; virtual;
    function  IsEmpty: boolean; override;
  end; { TOmniBaseQueue }

  TOmniQueue = class(TOmniBaseQueue, IOmniRingBuffer, IOmniNotifySupport, IOmniMonitorSupport)
  strict private
    orbMonitorSupport: IOmniMonitorSupport;
    orbNotifySupport : IOmniNotifySupport;
    orbOptions       : TOmniContainerOptions;
  public
    constructor Create(numElements, elementSize: integer;
      options: TOmniContainerOptions = [coEnableMonitor, coEnableNotify]);
    function  Dequeue(var value): boolean; override;
    function  Enqueue(const value): boolean; override;
    property MonitorSupport: IOmniMonitorSupport read orbMonitorSupport implements IOmniMonitorSupport;
    property NotifySupport: IOmniNotifySupport read orbNotifySupport implements IOmniNotifySupport;
    property Options: TOmniContainerOptions read orbOptions;
  end; { TOmniQueue }

implementation

uses
  Windows,
  SysUtils,
  DSiWin32;

type
  TOmniNotifySupport = class(TInterfacedObject, IOmniNotifySupport)
  strict private
    onsNewDataEvent: TDSiEventHandle;
  protected
    function  GetNewDataEvent: THandle;
  public
    constructor Create;
    destructor  Destroy; override;
    procedure Signal;
    property NewData: THandle read GetNewDataEvent;
  end; { TOmniNotifySupport }

{ TOmniNotifySupport }

constructor TOmniNotifySupport.Create;
begin
  inherited Create;
  onsNewDataEvent := CreateEvent(nil, false, false, nil);
  Win32Check(onsNewDataEvent <> 0);
end; { TOmniNotifySupport.Create }

destructor TOmniNotifySupport.Destroy;
begin
  DSiCloseHandleAndNull(onsNewDataEvent);
  inherited Destroy;
end; { TOmniNotifySupport.Destroy }

function TOmniNotifySupport.GetNewDataEvent: THandle;
begin
  Result := onsNewDataEvent;
end; { TOmniNotifySupport.GetNewDataEvent }

procedure TOmniNotifySupport.Signal;
begin
  Win32Check(SetEvent(onsNewDataEvent));
end; { TOmniNotifySupport.Signal }

{ TOmniBaseContainer }

destructor TOmniBaseContainer.Destroy;
begin
  FreeMem(obcBuffer);
end; { TOmniBaseStack.Destroy }

procedure TOmniBaseContainer.Empty;
var
  linkedData: POmniLinkedData;
begin
  repeat
    linkedData := PopLink(obcPublicChain);
    if not assigned(linkedData) then
      break; //repeat
    PushLink(linkedData, obcRecycleChain);
  until false;
end; { TOmniBaseStack.Empty }

procedure TOmniBaseContainer.Initialize(numElements, elementSize: integer);
var
  bufferElementSize: cardinal;
  currElement      : POmniLinkedData;
  iElement         : integer;
  nextElement      : POmniLinkedData;
begin
  Assert(SizeOf(cardinal) = SizeOf(pointer));
  Assert(SizeOf(obcPublicChain) = 8);
  Assert(SizeOf(obcRecycleChain) = 8);
  if cardinal(@obcPublicChain) AND 7 <> 0 then
    raise Exception.Create('TOmniBaseContainer: obcPublicChain is not 8-aligned');
  if cardinal(@obcRecycleChain) AND 7 <> 0 then
    raise Exception.Create('TOmniBaseContainer: obcRecycleChain is not 8-aligned');
  Assert(numElements > 0);
  Assert(elementSize > 0);
  obcNumElements := numElements;
  obcElementSize := elementSize;
  // calculate element size, round up to next 4-aligned value
  bufferElementSize := ((SizeOf(POmniLinkedData) + elementSize) + 3) AND NOT 3;
  GetMem(obcBuffer, bufferElementSize * cardinal(numElements));
  if cardinal(obcBuffer) AND 3 <> 0 then
    raise Exception.Create('TOmniBaseContainer: obcBuffer is not 4-aligned');
  //Format buffer to recycleChain, init orbRecycleChain and orbPublicChain.
  //At the beginning, all elements are linked into the recycle chain.
  obcRecycleChain.Head := obcBuffer;
  currElement := obcRecycleChain.Head;
  for iElement := 0 to obcNumElements - 2 do begin
    nextElement := POmniLinkedData(cardinal(currElement) + bufferElementSize);
    currElement.Next := nextElement;
    currElement := nextElement;
  end;
  currElement.Next := nil; // terminate the chain
  obcPublicChain.Head := nil;
end; { TOmniBaseStack.Initialize }

///<summary>Invert links in a chain.</summary>
///<returns>New chain head (previous tail) or nil if chain is empty.</returns>
///<since>2008-07-13</since>
class function TOmniBaseContainer.InvertOrder(chainHead: POmniLinkedData): POmniLinkedData;
asm
  test  eax, eax
  jz    @Exit
  xor   ecx, ecx
@Walk:
  xchg  [eax], ecx                        //Turn links
  and   ecx, ecx
  jz    @Exit
  xchg  [ecx], eax
  and   eax, eax
  jnz   @Walk
  mov   eax, ecx
@Exit:
end; { TOmniBaseStack.InvertOrder }

function TOmniBaseContainer.IsEmpty: boolean;
begin
  Result := not assigned(obcPublicChain.Head);
end; { TOmniBaseStack.IsEmpty }

function TOmniBaseContainer.IsFull: boolean;
begin
  Result := not assigned(obcRecycleChain.Head);
end; { TOmniBaseStack.IsFull }

///<summary>Removes first element from the chain, atomically.</summary>
///<returns>Removed first element. If the chain is empty, returns nil.</returns>
class function TOmniBaseContainer.PopLink(var chain: TOmniHeadAndSpin): POmniLinkedData;
//nil << Link.Next << Link.Next << ... << Link.Next
//FILO buffer logic                         ^------ < chainHead
asm
  push  edi
  push  ebx
  mov   edi, eax                          //edi = @chain
@Spin:
  mov   ecx, 1                            //Increment spin reference for 1
  lock xadd [edi + 4], ecx                //Get old spin reference to ecx
  mov   eax, [edi]                        //eax := chain.Head
  mov   edx, [edi +4]                     //edx := chain.Spin
  test  eax, eax
  jz    @Exit                             //Is Empty?
  inc   ecx                               //Now we are ready to cmpxchg8b
  cmp   edx, ecx                          //Is reference the some?
  jnz   @Spin
  mov   ebx, [eax]                        //ebx := Result.Next
  lock cmpxchg8b [edi]                    //Now try to xchg
  jnz   @Spin                             //Do spin ???
@Exit:
  pop   ebx
  pop   edi
end;

///<summary>Inserts element at the beginning of the chain, atomically.</summary>
class procedure TOmniBaseContainer.PushLink(const link: POmniLinkedData; var chain:
  TOmniHeadAndSpin);
//nil << Link.Next << Link.Next << ... << Link.Next
//FILO buffer logic                         ^------ < chainHead
asm
  mov   ecx, eax
  mov   eax, [edx]                         //edx = chain.Head
@Spin:
  mov   [ecx], eax                         //link.Next := chain.Head
  lock cmpxchg [edx], ecx                  //chain.Head := link
  jnz   @Spin
end; { TOmniBaseStack.PushLink }

///<summary>Removes all elements from a chain, atomically.</summary>
///<returns>Head of the chain.</returns>
///<since>2008-07-13</since>
class function TOmniBaseContainer.UnlinkAll(var chain: TOmniHeadAndSpin): POmniLinkedData;
//nil << Link.Next << Link.Next << ... << Link.Next
//FILO buffer logic                        ^------ < chain.Head
asm
  xor   ecx, ecx
  mov   edx, eax
  mov   eax, [edx]
@Spin:
  lock cmpxchg [edx], ecx                 //Cut Chain.Head
  jnz   @Spin
end; { TOmniQueue.UnlinkAll }

{ TOmniBaseStack }

function TOmniBaseStack.Pop(var value): boolean;
var
  linkedData: POmniLinkedData;
begin
  linkedData := PopLink(obcPublicChain);
  Result := assigned(linkedData);
  if not Result then
    Exit;
  Move(linkedData.Data, value, ElementSize);
  PushLink(linkedData, obcRecycleChain);
end; { TOmniBaseStack.Pop }

function TOmniBaseStack.Push(const value): boolean;
var
  linkedData: POmniLinkedData;
begin
  linkedData := PopLink(obcRecycleChain);
  Result := assigned(linkedData);
  if not Result then
    Exit;
  Move(value, linkedData.Data, ElementSize);
  PushLink(linkedData, obcPublicChain);
end; { TOmniBaseStack.Push }

{ TOmniStack }

constructor TOmniStack.Create(numElements, elementSize: integer;
  options: TOmniContainerOptions);
begin
  inherited Create;
  Initialize(numElements, elementSize);
  osOptions := options;
  if coEnableMonitor in Options then
    osMonitorSupport := CreateOmniMonitorSupport;
  if coEnableNotify in Options then
    osNotifySupport := TOmniNotifySupport.Create;
end; { TOmniStack.Create }

function TOmniStack.Pop(var value): boolean;
begin
  Result := inherited Pop(value);
  if Result then
    if coEnableNotify in Options then
      osNotifySupport.Signal;
end; { TOmniStack.Pop }

function TOmniStack.Push(const value): boolean;
begin
  Result := inherited Push(value);
  if Result then begin
    if coEnableNotify in Options then
      osNotifySupport.Signal;
    if coEnableMonitor in Options then
      osMonitorSupport.Notify;
  end;
end; { TOmniStack.Push }

{ TOmniBaseQueue }

constructor TOmniBaseQueue.Create;
begin
  Assert(SizeOf(obqDequeuedMessages) = 8);
  if cardinal(@obqDequeuedMessages) AND 7 <> 0 then
    raise Exception.Create('obqDequeuedMessages is not 8-aligned');
end; { TOmniBaseQueue.create }

function TOmniBaseQueue.Dequeue(var value): boolean;
var
  linkedData: POmniLinkedData;
begin
  if obqDequeuedMessages.Head = nil then
    obqDequeuedMessages.Head := InvertOrder(UnlinkAll(obcPublicChain));
  linkedData := PopLink(obqDequeuedMessages);
  Result := assigned(linkedData);
  if not Result then
    Exit;
  Move(linkedData.Data, value, ElementSize);
  PushLink(linkedData, obcRecycleChain);
end; { TOmniQueue.Dequeue }

procedure TOmniBaseQueue.Empty;
var
  linkedData: POmniLinkedData;
begin
  inherited;
  if assigned(obqDequeuedMessages.Head) then repeat
    linkedData := PopLink(obqDequeuedMessages);
    if not assigned(linkedData) then
      break; //repeat
    PushLink(linkedData, obcRecycleChain);
  until false;
end; { TOmniQueue.Empty }

function TOmniBaseQueue.Enqueue(const value): boolean;
var
  linkedData: POmniLinkedData;
begin
  linkedData := PopLink(obcRecycleChain);
  Result := assigned(linkedData);
  if not Result then
    Exit;
  Move(value, linkedData.Data, ElementSize);
  PushLink(linkedData, obcPublicChain);
end; { TOmniQueue.Enqueue }

function TOmniBaseQueue.IsEmpty: boolean;
begin
  Result := not (assigned(obcPublicChain.Head) or assigned(obqDequeuedMessages.Head));
end; { TOmniQueue.IsEmpty }

{ TOmniQueue }

constructor TOmniQueue.Create(numElements, elementSize: integer;
  options: TOmniContainerOptions);
begin
  inherited Create;
  Initialize(numElements, elementSize);
  orbOptions := options;
  if coEnableMonitor in Options then
    orbMonitorSupport := CreateOmniMonitorSupport;
  if coEnableNotify in Options then
    orbNotifySupport := TOmniNotifySupport.Create;
end; { TOmniQueue.Create }

function TOmniQueue.Dequeue(var value): boolean;
begin
  Result := inherited Dequeue(value);
  if Result then
    if coEnableNotify in Options then
      orbNotifySupport.Signal;
end; { TOmniQueue.Dequeue }

function TOmniQueue.Enqueue(const value): boolean;
begin
  Result := inherited Enqueue(value);
  if Result then begin
    if coEnableNotify in Options then
      orbNotifySupport.Signal;
    if coEnableMonitor in Options then
      orbMonitorSupport.Notify;
  end;
end; { TOmniQueue.Enqueue }

end.
