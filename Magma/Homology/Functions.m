import "../BasicData.m": K,L,V;
import "../Initialize.m": n,BBsym,LReg,dimsym,deg,C;





intrinsic ChooseBasis(LL::SeqEnum)->SeqEnum
 {Choose a Basis of a ColumnSpace out of a given List of ColumnVectors}
 LL:=[x: x in LL | x ne 0];
 res:=[LL[1]];
 for j in [2..#LL] do
  if Rank(Matrix(res cat [LL[j]])) gt Rank(Matrix(res)) then
   Append(~res,LL[j]);
  end if;
 end for;
 return res; 
end intrinsic;


intrinsic AllMinVecs(F::DAForm) -> SeqEnum
 {Take a list of vectors and return all multiples of them which still lie in the lattice and have the same idealnorm}
 S:=MinimalVectors(F);
 return [x: x in S] cat [-x: x in S];
end intrinsic;


intrinsic LowIndexStabilizer(F::DAForm,CheckMembership::Any) -> Grp
 {A function to determine the stabilizer in a subgroup of GL which comes with a function CheckMembership (which does just that)}
 S:=StabilizerOfMinimalClass(F);
 Elements:=[x: x in S | CheckMembership(x)];
 order:=Order(MatrixGroup<n,K|Elements>);
 Gens:=[Elements[1]];
 H:=MatrixGroup<n,K|Elements>;
 while Order(H) ne order do
  x:=Random(Elements);
  if not x in H then
   Append(~Gens,x);
   H:=MatrixGroup<n,K|Gens>;
  end if;
 end while;
 return H;
end intrinsic;


intrinsic BoundaryEmbeddings(LargeFace::DAForm,SmallFace::DAForm,CheckMembership::Any)->SeqEnum
 {Find Matrices in GL(L) such that g*SmallFace is in the boundary of LargeFace}
 //Both LargeFace and SmallFace need to be given by a representative of the minimal class, CheckMembership will check wether a matrix is in GL(L), We want  to construct g in GL(L) such that minvecs(LargeFace)g subset minvecs(SmallFace)
 Target:=AllMinVecs(SmallFace);  //These are all possible images of minvecs(LargeFace) 
 M:=MinimalVectors((LargeFace));
 Source:=ChooseBasis(M); 
 ImageSets:=Subsets({x: x in Target},n);
 ImageSets:=[SetToIndexedSet(x): x in ImageSets];
 Sn:=SymmetricGroup(n);
 ImageLists:=[];
 for g in Sn do 
  for x in ImageSets do	
   Append(~ImageLists,[x[i^g]: i in [1..n]]);
  end for;
 end for;
 
 ImageLists:=[x:x in ImageLists|  Determinant(Matrix(x)) ne 0]; // Now ImageList is a list of all possible tuples [w1,...,wn] such that v1g=w1,...,vng=wn possibly determines an element g in GL(L) which might fit the bill
 Inv:=Transpose(Matrix(Source))^(-1);
 PossibleElementsList:=[Transpose(Matrix(x))*Inv: x in ImageLists]; // This is a list of all possible GroupElements such that g^-1 SmallFace might be in the boundary of LargeFace
 PossibleElementsList:=[g: g in PossibleElementsList | CheckMembership(g)]; //Now only elements of GL(L) remain
 PossibleElementsList:=[g: g in PossibleElementsList | {g*m: m in M} subset {v: v in Target}]; // Now only elements remain which really fulfill g SmallFace in the boundary of LargeFace
 if #PossibleElementsList eq 0 then 
  return [];
 end if;
 PossibleElementsList:=[(g^-1): g in PossibleElementsList]; //Fixing the inverse .
 FinalOutput:=[PossibleElementsList[1]];
 //Now we will make the list duplicate free
 SmallFaceStab:=StabilizerOfMinimalClass(SmallFace);
 for g in PossibleElementsList do
  bool:=true;
  for h in FinalOutput do
   if h^(-1)*g in SmallFaceStab then	
    bool:=false;
    break h;
   end if;
  end for;
  if bool then	
   Append(~FinalOutput,g);
  end if;
 end for;
 return FinalOutput;
end intrinsic;



intrinsic Vertices(F::DAForm,V::VData) -> SeqEnum
 {This will give a list of all perfect forms in the boundary of a minimal class represented by F}
 if not assigned(V`MinimalClasses) then
  MinimalClasses(V);
 end if;
 FormREPS:=V`MinimalClasses;
 output:=[**];
 for i in [1..#FormREPS[1]] do
  for x in BoundaryEmbeddings(F,FormREPS[1][i], IsIntegralUnit) do
   Append(~output,[*i,x*]);
  end for;
 end for;
 return output;
end intrinsic;



intrinsic OrientationSignByDeterminant(F::DAForm,g::Mtrx,W::VData) -> RngIntElt 
 {Computes the orientation action of g on the minimal class represented by F via the use of determinants}
 if not assigned(W`MinimalClasses) then
  MinimalClasses(W);
 end if;
 FormREPS:=W`MinimalClasses;
 //V:=Vertices(F,W);   //This is the time consuming part
 //Let's try something else
 k:=PerfectionCorank(F);
 FormREPS:=W`MinimalClasses;
 output:=[**];
 kk:=k eq 0 select 0 else k-1;
 if k eq 0 then return 1; end if;
 for i in [1..#FormREPS[kk+1]] do
  for x in BoundaryEmbeddings(F,FormREPS[kk+1][i], IsIntegralUnit) do
   Append(~output,[*i,x*]);
  end for;
 end for;
 V:=output;
 V:=[Dagger(y[2]^-1)*FormREPS[kk+1][y[1]]`Matrix*(y[2]^-1): y in V];
 //Until here is something else
 //V:=[y[2]*FormREPS[1][y[1]]`Matrix*HermitianTranspose(y[2]): y in V];
 GensOfTSpace:=[V[1]-V[i]: i in [1..#V]];
 GensOfTSpaceRat:=[SymmetricCoordinates(y): y in GensOfTSpace];
 Indices:=[];         //Now we choose a (Q)-Basis for the Space of Translations of affine space generated by the given class
 T:=KMatrixSpace(Rationals(),#GensOfTSpaceRat,dimsym)!GensOfTSpaceRat;
 T:=Transpose(T);
 T:=EchelonForm(T);
 for i in [1..NumberOfRows(T)] do
  for j in [1..NumberOfColumns(T)] do
   if T[i][j] ne 0 then
    Append(~Indices,j); break;
   end if;
  end for;
 end for;
 Space:=KSpaceWithBasis(KMatrixSpace(Rationals(),#Indices,dimsym)![GensOfTSpaceRat[i]: i in Indices]);
 while Dimension(Space) ne k do
  kk:=kk-1;
  for i in [1..#FormREPS[kk+1]] do
   for x in BoundaryEmbeddings(F,FormREPS[kk+1][i], IsIntegralUnit) do
    Append(~output,[*i,x*]);
   end for;
  end for;
  V:=output;
  V:=[Dagger(y[2]^-1)*FormREPS[kk+1][y[1]]`Matrix*(y[2]^-1): y in V];
  //Until here is something else
  //V:=[y[2]*FormREPS[1][y[1]]`Matrix*HermitianTranspose(y[2]): y in V];
  GensOfTSpace:=[V[1]-V[i]: i in [1..#V]];
  Append(~GensOfTSpaceRat,[SymmetricCoordinates(y): y in GensOfTSpace]);
  Indices:=[];         //Now we choose a (Q)-Basis for the Space of Translations of affine space generated by the given class
  T:=KMatrixSpace(Rationals(),#GensOfTSpaceRat,dimsym)!GensOfTSpaceRat;
  T:=Transpose(T);
  T:=EchelonForm(T);
  for i in [1..NumberOfRows(T)] do
   for j in [1..NumberOfColumns(T)] do
    if T[i][j] ne 0 then
     Append(~Indices,j); break;
    end if;
   end for;
  end for;
  Space:=KSpaceWithBasis(KMatrixSpace(Rationals(),#Indices,dimsym)![GensOfTSpaceRat[i]: i in Indices]);
 end while;
 Images:=[Dagger(g)*GensOfTSpace[i]*(g): i in Indices];
 Images:=[SymmetricCoordinates(y): y in Images];
 MatrixRep:=[Coordinates(Space,Space!y):y in Images];   //We determine the basis representation of the images under g
 return Sign(Determinant(MatrixRing(Rationals(),Dimension(Space))!MatrixRep));
end intrinsic;


 
intrinsic EvenStabilizerOfMinimalClass(F::DAForm,V::VData) -> Grp
 {This will compute the orientation preserving subgroup of the stabilizer of a minimal class, this is a normal subgroup of index 1 or 2 }
 Stab:=StabilizerOfMinimalClass(F);
 index:=1;
 for g in Generators(Stab) do             //Let us first determine whether the index is 1 or 2.
  if OrientationSignByDeterminant(F,g,V) eq -1 then
   index:=2;
   break;
  end if;
 end for;
 if index eq 1 then 
  return Stab;
 end if;
 EvenGenerators:={};
 Ordnung:=Order(Stab)/2;
 S:=MatrixGroup<n,K|[y : y in EvenGenerators]>;
 while Order(S) ne Ordnung do    //We add new elements until the order is large enough
  x:=Random(Stab);
  if x in S then continue; end if;
  if OrientationSignByDeterminant(F,x,V) eq 1 then
   Include(~EvenGenerators,x);
  else
   Include(~EvenGenerators,x^2);
  end if;
  S:=MatrixGroup<n,K|[y : y in EvenGenerators]>;
 end while;
 return S;
end intrinsic;


intrinsic LowIndexEvenStabilizer(F::DAForm,CheckMembership::Any,V::VData) -> SeqEnum
 {This will compute the orientation preserving subgroup of the stabilizer of a minimal class (in a subgroup of GL), this is a normal subgroup of index 1 or 2 }
 Stab:=LowIndexStabilizer(F,CheckMembership);
 index:=1;
 for g in Generators(Stab) do             //Let us first determine whether the index is 1 or 2.
  if OrientationSignByDeterminant(F,g,V) eq -1 then
   index:=2;
   break;
  end if;
 end for;
 if index eq 1 then 
  return Stab;
 end if;
 EvenGenerators:={};
 Ordnung:=Order(Stab)/2;
 while Order(MatrixGroup<n,K|[y : y in EvenGenerators]>) ne Ordnung do    //We add new elements until the order is large enough since I have no better idea.
  x:=Random(Stab);
  if OrientationSignByDeterminant(F,x,V) eq 1 then
   Include(~EvenGenerators,x);
  end if;
 end while;
 return MatrixGroup<n,K|[x: x in EvenGenerators]>;
end intrinsic;


intrinsic IsInSL(g::Mtrx) -> BoolElt
 {A function to check wether something is in SL}
 return IsIntegralUnit(g) and Determinant(g) eq 1;
end intrinsic;

//An implementation of product replacement:
Step:=function(T)
 L:=#(T);
 i:=Random(1,L);
 j:=Random(1,L);
 while i eq j 
  do j:=Random(1,L); 
 end while;
 eps:=Random(0,1);
 if eps eq 1 
  then T[i]:=T[i]*T[j]; 
 else 
  T[i]:=T[j]^(-1)*T[i]; 
 end if;
 return T;
end function;


PR:=function(X,B)
 T:=[];
 A:=X[1]*X[1]^(-1);
 for i in [1..Max(#(X)+2,10)] do
  if i le #(X) 
   then T[i]:=X[i]; 
  else 
   T[i]:=1; 
  end if; 
 end for;
 for i in [1..B] do 
  j:=Random(1,#(T)); 
  T:=Step(T); 
  eps:=Random(0,1);
  if eps eq 1 
   then A:=T[j]*A; 
  else 
   A:=T[j]^(-1)*A; 
  end if; 
 end for;
 return A;
end function;

 
intrinsic IsInCongruenceSubgroupTest(p::RngQuadIdl) ->Any
 {A function to produce the checkmembershipfunction for the full congruence subgroup of level p}
 f:=function(M)
  return IsInSL(M) and {M[1][1]-1 in p,M[1][2] in p, M[2][1] in p, M[2][2]-1 in p} eq {true};
 end function;
 return f;
end intrinsic;


intrinsic SystemOfRepresentativesFiniteIndex(gens::Any,CheckMembership::Any,ind::RngIntElt)-> SeqEnum
 {A function to compute a system of representatives in GL if we know the index of the subgroup and a function to check for membership}
 reps:=[Parent(gens[1])!1];
 iterations:=2;
 counter:=1;
 while #reps ne ind do
  if counter mod 100 eq 0 then
   iterations+:=1;
  end if;
  x:=PR(gens,iterations);
  if {CheckMembership(y*x^(-1)):y in reps} eq {false} then
   Append(~reps,x);
  end if;
 counter:=counter+1;
 end while;
 return reps;
end intrinsic;













