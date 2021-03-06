
# GENERATED FROM ExtendedBehaviorTrees.org.
# DO NOT EDIT THIS FILE!

# Copyright © 2014, Matthias Hölzl
# Licensed under the MIT license, see the file LICENSE.md.

module ExtendedBehaviorTrees

export XbtNodeStatus, Inactive, Running, Succeeded, Failed;

abstract XbtNodeStatus;
immutable Inactive <: XbtNodeStatus end;
immutable Running <: XbtNodeStatus end;
immutable Succeeded <: XbtNodeStatus
    value
end;
immutable Failed <: XbtNodeStatus end;

export isinactive, isrunning, issucceeded, isfailed;

isinactive(x) = false;
isinactive(x::Inactive) = true;

isrunning(x) = false;
isrunning(x::Running) = true;

issucceeded(x) = false;
issucceeded(x::Succeeded) = true;

isfailed(x) = false;
isfailed(x::Failed) = true;

export XbtNodeResult;
typealias XbtNodeResult (XbtNodeStatus, Bool);

export isdone;
isdone(x) = false;
isdone(x::XbtNodeResult) = isdone(x...);
isdone(x, cont) = false;
isdone(x::Succeeded, cont::Bool) = !cont;
isdone(x::Failed, cont::Bool) = true;

export failed, running, succeeded;
const failed = (Failed(), false);
const running = (Running(), true);
succeeded(val, cont=false) = (Succeeded(val), cont);

export XbtNode, AtomicXbtNode, CompositeXbtNode;
abstract XbtNode;
abstract AtomicXbtNode <: XbtNode;
abstract CompositeXbtNode <: XbtNode;

export status, setstatus;
status(node::XbtNode) = node.status;
setstatus(node::XbtNode, status::XbtNodeStatus) = node.status = status;

export cont, setcont;
cont(node::XbtNode) = node.cont;
setcont(node::XbtNode, cont::Bool) = node.cont = cont;

export result, setresult;
result(node::XbtNode) = status(node), cont(node);

function setresult(node::XbtNode, result::XbtNodeResult)
    setstatus(node, result[1])
    setcont(node, result[2])
    result
end;

isinactive(node::XbtNode) = isinactive(status(node));
isrunning(node::XbtNode) = isrunning(status(node));
issucceeded(node::XbtNode) = issucceeded(status(node));
isfailed(node::XbtNode) = isfailed(status(node));
isdone(node::XbtNode) = isdone(status(node), cont(node));

export setinactive;
function setinactive(node::XbtNode)
    setstatus(node, Inactive());
    setcont(node, true); # Slightly superfluous
end;

type XbtTask <: AtomicXbtNode
    task::Task
    status::XbtNodeStatus
    cont::Bool
end;

function XbtTask(fun::Function, status::XbtNodeStatus, cont::Bool)
    XbtTask(Task(fun), status, cont);
end;
XbtTask(task, status) = XbtTask(task, status, false);
XbtTask(task) = XbtTask(task, Inactive());

function tick(node::XbtTask, state)
    if (isdone(node))
        return result(node)
    end
    setresult(node, consume(node.task))
end;

type XbtFun <: AtomicXbtNode
    fun::Function
    status::XbtNodeStatus
    cont::Bool
end;

XbtFun(fun::Function, status::XbtNodeStatus) = XbtFun(task, status, false);
XbtFun(fun::Function) = XbtFun(fun, Inactive());

function tick(node::XbtFun, state)
    if (isdone(node))
        return result(node)
    end
    setresult(node, node.fun())
end;

abstract XbtSequenceNode <: CompositeXbtNode;

function tick(node::XbtSequenceNode, state)
    local sum = 0, status, cont;
    for child in node.children
        status, cont = tick(child, state);
        if isa(status, Failed) return (status, false) end;
        if isa(status, Running) return (status, true) end;
        sum += status.value;
    end;
    # TODO: what about continuing?
    return Succeeded(sum, false), cont;
end;

immutable XbtSeq <: XbtSequenceNode
    children::AbstractArray{XbtNode,1}
end;

abstract XbtChoiceNode <: CompositeXbtNode;

function tick(node::XbtChoiceNode, state)
    local status, cont;
    for child in node.children
        status, cont = tick(child, state);
        if isa(status, Succeeded) return (status, cont) end;
        if isa(status, Running) return (status, true) end;
    end;
    return Failed(), cont;
end;

immutable XbtChoice <: XbtChoiceNode
    children::AbstractArray{XbtNode,1}
end;

end; # module ExtendedBehaviorTrees
